// lib/controllers/accueil_controller.dart
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/repo/offline_repo.dart';

typedef AccueilData = ({
  String nomAtelier,
  List<CommandeModel> commandes,
  int enCours,
  int pretes,
});

sealed class AccueilState {}

class AccueilLoading extends AccueilState {}

class AccueilSuccess extends AccueilState {
  final AccueilData data;
  final bool estEnArrierePlan;
  AccueilSuccess(this.data, {this.estEnArrierePlan = false});
}

class AccueilError extends AccueilState {
  final String message;
  AccueilError(this.message);
}

class AccueilController extends ValueNotifier<AccueilState> {
  final OfflineRepository _commandesRepo;
  final OfflineRepository _atelierRepo;
  final OfflineRepository _clientsRepo;

  AccueilController({
    OfflineRepository? commandesRepo,
    OfflineRepository? atelierRepo,
    OfflineRepository? clientsRepo,
  }) : _commandesRepo = commandesRepo ?? OfflineRepository('commandes'),
       _atelierRepo = atelierRepo ?? OfflineRepository('ateliers'),
       _clientsRepo = clientsRepo ?? OfflineRepository('clients'),
       super(AccueilLoading());

  Future<AccueilData> _construireData() async {
    final cacheCommandes = await _commandesRepo.lireCache();
    final cacheAtelier = await _atelierRepo.lireCache();
    final cacheClients = await _clientsRepo.lireCache();

    // 1. Création de la Map [ID_CLIENT -> NOM_CLIENT] depuis le cache clients
    final Map<String, String> clientsMap = {};
    for (var c in cacheClients) {
      final clientIdKey = (c['id'] ?? c['id_client'] ?? c['record_id'] ?? '')
          .toString();
      final clientNomVal =
          (c['nom'] ??
                  c['nom_client'] ??
                  c['nomClient'] ??
                  c['name'] ??
                  'Client inconnu')
              .toString();

      if (clientIdKey.isNotEmpty) {
        clientsMap[clientIdKey] = clientNomVal;
      }
    }

    // 2. Traitement du nom de l'atelier
    String nomAtelier = 'Mon Atelier';
    if (cacheAtelier.isNotEmpty) {
      final map = cacheAtelier.first;
      final nomBrut = map['nom'];
      if (nomBrut != null && nomBrut.toString().trim().isNotEmpty) {
        nomAtelier = nomBrut.toString();
      }
    }

    // 3. Conversion et injection du nom du client (Stratégie multi-fallback)
    final List<CommandeModel> listCommandes = cacheCommandes.map((map) {
      final clientId =
          (map['client'] ??
                  map['client_id'] ??
                  map['clientId'] ??
                  map['customer'] ??
                  '')
              .toString();

      final mapModifiee = Map<String, dynamic>.from(map);
      String? nomFinal;

      // Niveau 1 : Regarder si le nom a été directement enrichi dans la commande
      if (map['client_nom'] != null &&
          map['client_nom'].toString().trim().isNotEmpty) {
        nomFinal = map['client_nom'].toString();
      }

      // Niveau 2 : Jointure manuelle via le cache clientsMap
      if ((nomFinal == null || nomFinal.isEmpty) && clientId.isNotEmpty) {
        nomFinal = clientsMap[clientId];
      }

      // Niveau 3 : Regarder la clé expand brute si présente
      if (nomFinal == null || nomFinal.isEmpty) {
        if (map['expand_client'] != null &&
            map['expand_client']['nom'] != null) {
          nomFinal = map['expand_client']['nom'].toString();
        }
      }

      // Application du résultat ou fallback final
      mapModifiee['clientNom'] =
          (nomFinal != null && nomFinal.trim().isNotEmpty) ? nomFinal : '—';

      return CommandeModel.fromCacheMap(mapModifiee);
    }).toList();

    // 4. Calculs des statistiques
    final enCours = listCommandes
        .where(
          (c) =>
              c.statut.toLowerCase().contains('cours') ||
              c.statut.toLowerCase().contains('attente'),
        )
        .length;

    final pretes = listCommandes
        .where(
          (c) =>
              c.statut.toLowerCase().contains('prêt') ||
              c.statut.toLowerCase().contains('pret'),
        )
        .length;

    return (
      nomAtelier: nomAtelier,
      commandes: listCommandes,
      enCours: enCours,
      pretes: pretes,
    );
  }

  Future<void> charger({bool afficherLoading = true}) async {
    // 1. Charger et afficher d'abord ce qui existe en cache local
    try {
      final dataLocal = await _construireData();
      value = AccueilSuccess(dataLocal);
    } catch (e) {
      if (afficherLoading) value = AccueilLoading();
    }

    // 2. Mettre à jour TOUTES les données depuis le réseau
    try {
      // Étape A : Synchroniser les ateliers et les clients
      await Future.wait([_atelierRepo.actualiser(), _clientsRepo.actualiser()]);

      // Étape B : Synchroniser les commandes en tirant parti du "expand" PocketBase
      await _commandesRepo.actualiser(
        expand: 'client',
        enrichir: (record) {
          String? clientNom;
          final clientExpand = record.expand['client'];

          if (clientExpand != null && clientExpand.isNotEmpty) {
            // clientExpand.first est le RecordModel du client lié
            final RecordModel clientRecord = clientExpand.first;
            clientNom = clientRecord.data['nom']?.toString();
          }

          return {'client_nom': clientNom};
        },
      );

      // 3. Reconstruire l'interface avec les données synchronisées et enrichies
      final dataAjour = await _construireData();
      value = AccueilSuccess(dataAjour);
    } catch (e) {
      debugPrint('ERREUR SYNC ACCUEIL : $e');
      if (value is! AccueilSuccess) {
        value = AccueilError('Impossible de charger les données.');
      }
    }
  }

  Future<void> rafraichir() async {
    if (value is AccueilSuccess) {
      final currentData = (value as AccueilSuccess).data;
      value = AccueilSuccess(currentData, estEnArrierePlan: true);
    }
    await charger(afficherLoading: false);
  }
}
