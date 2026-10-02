import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';
import 'package:teler_pro/provider/repo_provider.dart';
import 'package:teler_pro/repo/offline_repo.dart';

part 'commande_ctr.g.dart';

@riverpod
class CommandesController extends _$CommandesController {
  final _commandesRepo = OfflineRepository('commandes');
  final _paiementsRepo = OfflineRepository('paiements');

  // Filtre actif stocké dans l'état du notifier
  String _filtreActuel = 'toutes';
  String get filtreActuel => _filtreActuel;

  @override
  FutureOr<List<CommandeModel>> build() async {
    return _chargerDonnees();
  }

  // --- Chargement Hybride (Cache immédiat + Sync Réseau) ---
  Future<List<CommandeModel>> _chargerDonnees() async {
    final atelier = await atelierService.atelierCourant();
    final atelierId = atelier['id'] as String;

    // 1. Chargement instantané depuis le cache local (Hive)
    final cache = await _commandesRepo.lireCache();
    final paiementsCache = await _paiementsRepo.lireCache();
    final commandesLocales = await _construireListe(
      cache,
      paiementsCache,
      atelierId,
    );

    return commandesLocales;
  }

  Future<List<CommandeModel>> _construireListe(
    List<Map<String, dynamic>> commandesBrutes,
    List<Map<String, dynamic>> paiementsBruts,
    String atelierId,
  ) async {
    final clientsCache = await OfflineRepository('clients').lireCache();

    var filtrees = commandesBrutes.where((c) => c['atelier'] == atelierId);

    // 💡 Filtrage tolérant avec gestion des équivalences de statuts
    if (_filtreActuel != 'toutes') {
      filtrees = filtrees.where((c) {
        final statutDb = (c['statut'] as String? ?? '').trim().toLowerCase();
        final filtre = _filtreActuel.trim().toLowerCase();

        if (filtre == 'attente') {
          return statutDb == 'attente' || statutDb == 'en_attente';
        }
        if (filtre == 'en_cours') {
          return statutDb == 'en_cours' || statutDb == 'cours';
        }
        if (filtre == 'pret') {
          return statutDb == 'pret' || statutDb == 'prete';
        }
        if (filtre == 'livre') {
          return statutDb == 'livre' || statutDb == 'livree';
        }

        return statutDb == filtre;
      });
    }

    return filtrees.map((c) {
      final commandeMap = Map<String, dynamic>.from(c);
      final commandeId = commandeMap['id'] as String? ?? '';

      // Résolution du nom de client
      String? nomTrouve =
          commandeMap['clientNom'] as String? ??
          commandeMap['client_nom'] as String?;
      if (nomTrouve == null || nomTrouve.trim().isEmpty) {
        final clientId = commandeMap['client'] as String? ?? '';
        final clientMap = clientsCache.firstWhere(
          (cli) => cli['id'] == clientId,
          orElse: () => <String, dynamic>{},
        );
        if (clientMap.isNotEmpty) {
          final nom = clientMap['nom'] as String? ?? '';
          final prenom = clientMap['prenom'] as String? ?? '';
          nomTrouve = '$nom $prenom'.trim();
        }
      }
      if (nomTrouve != null && nomTrouve.isNotEmpty) {
        commandeMap['clientNom'] = nomTrouve;
      }

      final montantPaye = paiementsBruts
          .where((p) => p['commande'] == commandeId)
          .fold<double>(
            0.0,
            (s, p) => s + ((p['montant'] as num?)?.toDouble() ?? 0.0),
          );

      return CommandeModel.fromCacheMap(commandeMap, montantPaye: montantPaye);
    }).toList()..sort(
      (a, b) => (a.dateLivraisonPrevue ?? DateTime(2100)).compareTo(
        b.dateLivraisonPrevue ?? DateTime(2100),
      ),
    );
  }

  // --- ACTIONS ---
  Future<void> suprimerCommande(String commandeId) async {
    state.whenData((commande) {
      state = AsyncData(commande.where((c) => c.id != commandeId).toList());
    });
    try {
      await _commandesRepo.supprimer(commandeId);
      ref.read(syncManagerProvider.notifier).synchronizeCollections();
    }catch(e , st){
      ref.invalidateSelf();
    }

  }

  /// Changer le filtre de recherche (Toutes, En attente, Livré, etc.)
  Future<void> changerFiltre(String nouveauFiltre) async {
    if (_filtreActuel == nouveauFiltre) return;
    _filtreActuel = nouveauFiltre;

    // Déclenche un rechargement complet avec indicateur de chargement
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _chargerDonnees());
  }

  /// Forcer le rafraîchissement manuel (Pull-to-refresh)
  Future<void> rafraichir() async {
    ref.invalidateSelf();
    await future;
  }
}
