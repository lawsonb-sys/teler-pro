import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';
import 'package:teler_pro/provider/repo_provider.dart';
import 'package:teler_pro/repo/offline_repo.dart';

part 'clients_controller.g.dart';

@riverpod
class ClientsController extends _$ClientsController {
  final _clientsRepo = OfflineRepository('clients');
  final _commandesRepo = OfflineRepository('commandes');

  Future<String> get atelierId async {
    final atelier = await AtelierService().atelierCourant();
    return atelier['id'] as String;
  }

  @override
  FutureOr<List<ClientModel>> build() async {
    return chargerDonnees();
  }

  // --- Chargement Hybride (Cache immédiat + Sync Réseau) ---
  Future<List<ClientModel>> chargerDonnees() async {
    final cache = await _clientsRepo.lireCache();
    final clientsLocales = await _construireListe(cache);
    return clientsLocales;
  }

  Future<List<ClientModel>> _construireListe(
    List<Map<String, dynamic>> clientsBruts,
  ) async {
    try {
      final idAtelier = await atelierId;
      return clientsBruts
          .where((c) => c['atelier'] == idAtelier)
          .map((c) => ClientModel.fromMap(c))
          .toList();
    } catch (e) {
      // En cas d'erreur, on retourne la liste brute sans filtrage
      return clientsBruts.map((c) => ClientModel.fromMap(c)).toList();
    }
  }

  List<ClientModel> _versModeles(
    List<Map<String, dynamic>> clientsBruts,
    String atelierIdCourant,
  ) {
    try {
      return clientsBruts
          .where((c) => c['atelier'] == atelierIdCourant)
          .map((c) => ClientModel.fromMap(c))
          .toList();
    } catch (_) {
      return clientsBruts.map((c) => ClientModel.fromMap(c)).toList();
    }
  }

  // =========================================================================
  // --- APPROCHE 2 : Chargement à la demande des commandes d'un client ---
  // =========================================================================

  /// Récupère les commandes associées à un client spécifique
  Future<List<CommandeModel>> chargerCommandesDuClient(String clientId) async {
    try {
      // 1. Lire toutes les commandes depuis le cache local (ou dépôt)
      final commandesBrutes = await _commandesRepo.lireCache();

      // 2. Filtrer les commandes appartenant à ce client
      return commandesBrutes
          .where((cmd) => cmd['client'] == clientId)
          .map((cmd) => CommandeModel.fromMap(cmd))
          .toList();
    } catch (e) {
      print('Erreur lors du chargement des commandes du client $clientId : $e');
      return [];
    }
  }

  /// Optionnel : Enrichir un objet [ClientModel] existant avec sa liste de commandes
  /*  Future<ClientModel> enrichirClientAvecCommandes(ClientModel client) async {
    final commandes = await chargerCommandesDuClient(client.id);
    return client.copyWith(commandes: commandes);
  }*/

  /// Modifier les informations d'un client existant
  Future<void> modifier(String clientId, Map<String, dynamic> body) async {
    try {
      // 1. Mise à jour dans le dépôt local (met à jour le cache local et tente la sync avec PocketBase)
      await _clientsRepo.modifier(clientId, body);

      // 2. Relecture immédiate du cache local mis à jour pour réactivité UI instantanée
      final cacheFrais = await _clientsRepo.lireCache();
      state = AsyncData(_versModeles(cacheFrais, await atelierId));

      ref.read(syncManagerProvider.notifier).synchronizeCollections();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> enregistrerclient(Map<String, dynamic> body) async {
    try {
      final nvMap = await _clientsRepo.creer(body);
      final nouveauclient = ClientModel.fromMap(nvMap);
      state.whenData((listactu) {
        state = AsyncData([nouveauclient, ...listactu]);
      });
      ref.read(syncManagerProvider.notifier).synchronizeCollections();
    } catch (e) {
      debugPrint('Erreur lors de la creation : $e');
      ref.invalidateSelf();
    }
  }

  /// Méthode spécifique pour le RefreshIndicator de la vue
  /// Forcer le rafraîchissement manuel (Pull-to-refresh)
  Future<void> rafraichir() async {
    ref.invalidateSelf();
    await future;
  }
}
