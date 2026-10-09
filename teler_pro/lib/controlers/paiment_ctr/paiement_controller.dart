import 'dart:async';
import 'dart:io'; // 👈 Import obligatoire pour la gestion des fichiers
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teler_pro/controlers/command_ctr/commande_ctr.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/provider/repo_provider.dart';
import 'package:teler_pro/provider/test_ctr.dart';
import 'package:teler_pro/repo/offline_repo.dart';

part 'paiement_controller.g.dart';

// Structure de données locale pour la page
class PaiementDataState {
  final CommandeModel commande;
  final List<PaiementModel> paiements;

  PaiementDataState({required this.commande, required this.paiements});
}

@riverpod
class PaiementController extends _$PaiementController {
  final _commandesRepo = OfflineRepository('commandes');
  final _paiementsRepo = OfflineRepository('paiements');
  final _clientsRepo = OfflineRepository('clients');

  @override
  FutureOr<PaiementDataState> build(String commandeId) async {
    return _charger(commandeId);
  }

  // Chargement unifié depuis le cache local (Hive)
  Future<PaiementDataState> _charger(String commandeId) async {
    try {
      await _commandesRepo.actualiser();
      await _paiementsRepo.actualiser();
      await _clientsRepo.actualiser();
    } catch (e) {
      debugPrint('⚠️ [PaiementController] Mode hors-ligne ou erreur réseau: $e');
    }

    final cacheClients = await _clientsRepo.lireCache();
    final Map<String, String> mapClients = {
      for (var c in cacheClients)
        c['id'].toString(): (c['nom'] ?? c['nom_client'] ?? 'Client inconnu')
            .toString(),
    };

    final cacheCommandes = await _commandesRepo.lireCache();
    final commandeMap = cacheCommandes.firstWhere(
          (c) => c['id'] == commandeId,
      orElse: () => {},
    );

    if (commandeMap.isEmpty) {
      throw Exception("Commande introuvable dans le cache local.");
    }

    final commandeMapComplete = Map<String, dynamic>.from(commandeMap);
    final clientId = commandeMapComplete['client']?.toString() ?? '';

    if (!commandeMapComplete.containsKey('clientNom') ||
        commandeMapComplete['clientNom'] == null ||
        commandeMapComplete['clientNom'] == '—') {
      commandeMapComplete['clientNom'] = mapClients[clientId] ?? '—';
    }

    final cachePaiements = await _paiementsRepo.lireCache();
    final paiements = cachePaiements
        .where((p) => p['commande'] == commandeId)
        .map((p) => PaiementModel.fromCacheMap(p))
        .toList();

    paiements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final montantPaye = paiements.fold<double>(0, (s, p) => s + p.montant);
    final commande = CommandeModel.fromCacheMap(
      commandeMapComplete,
      montantPaye: montantPaye,
    );

    return PaiementDataState(commande: commande, paiements: paiements);
  }

  // 1. CHANGER LE STATUT
  Future<void> changerStatut(String nouveauStatut) async {
    final currentData = state.value;
    if (currentData == null) return;

    // Mise à jour locale Hive
    await _commandesRepo.modifierTexte(currentData.commande.id, {
      'statut': nouveauStatut,
    });

    // Invalider les contrôleurs dépendants
    ref.invalidate(accueilControllerProvider);
    ref.invalidate(commandesControllerProvider);

    // Recharger la page actuelle
    state = await AsyncValue.guard(() => _charger(currentData.commande.id));
    ref.read(syncManagerProvider.notifier).synchronizeCollections();
  }

  // 2. ENREGISTRER UN PAIEMENT
  Future<void> enregistrerPaiement({
    required double montant,
    required String mode,
  }) async {
    final currentData = state.value;
    if (currentData == null) return;

    // Création dans Hive
    await _paiementsRepo.creer({
      'commande': currentData.commande.id,
      'montant': montant,
      'mode': mode,
    });

    // Invalider l'accueil
    ref.invalidate(accueilControllerProvider);

    // Recharger la page actuelle
    state = await AsyncValue.guard(() => _charger(currentData.commande.id));
    ref.read(syncManagerProvider.notifier).synchronizeCollections();
  }

  // 3. AJOUTER DES PHOTOS À LA COMMANDE EXISTANTE

  Future<void> ajouterPhotos(List<File> nouvellesPhotos) async {
    final currentData = state.value;
    if (currentData == null || nouvellesPhotos.isEmpty) return;

    final commandeId = currentData.commande.id;

    await _commandesRepo.modifierAvecPhotos(
      commandeId, // 1er argument positionnel : id
      {},          // 2e argument positionnel : body (Map vide)
      photos: nouvellesPhotos,
      nomChampFichier: 'photos',

    );

    // Invalidation et rafraîchissement
    ref.invalidate(accueilControllerProvider);
    ref.invalidate(commandesControllerProvider);

    state = await AsyncValue.guard(() => _charger(commandeId));

    // Déclenchement de la synchronisation
    ref.read(syncManagerProvider.notifier).synchronizeCollections();
  }
}