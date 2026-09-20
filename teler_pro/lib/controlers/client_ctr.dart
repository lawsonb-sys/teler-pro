// lib/controllers/clients_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';
import 'package:teler_pro/repo/offline_repo.dart';

class ClientsController extends ChangeNotifier {
  final _repo = OfflineRepository('clients');

  bool chargement = true;
  String? erreur;
  List<ClientModel> clients = [];
  String? _atelierIdCourant;

  StreamSubscription<List<Map<String, dynamic>>>? _abonnementCache;

  /// Initialise l'écoute du cache local et déclenche l'actualisation réseau
  Future<void> charger() async {
    chargement = true;
    erreur = null;
    notifyListeners();

    try {
      final atelier = await atelierService.atelierCourant();
      _atelierIdCourant = atelier['id'] as String;

      // 1. Lire immédiatement le cache local sans attendre le Stream
      final cacheInitial = await _repo.lireCache();
      clients = _versModeles(cacheInitial, _atelierIdCourant!);
      chargement = false;
      notifyListeners();

      // 2. Écoute permanente du cache Hive
      await _abonnementCache?.cancel();
      _abonnementCache = _repo.ecouterCache().listen((cache) {
        if (_atelierIdCourant != null) {
          clients = _versModeles(cache, _atelierIdCourant!);
          chargement = false;
          notifyListeners();
        }
      });

      // 3. En arrière-plan : Tente de récupérer les données fraîches depuis PocketBase
      await _repo.actualiser(filter: 'atelier = "$_atelierIdCourant"');
    } catch (e) {
      erreur = 'Une erreur est survenue : $e';
      chargement = false;
      notifyListeners();
    }
  }

  /// Modifier les informations d'un client existant
  Future<void> modifier(String clientId, Map<String, dynamic> body) async {
    try {
      erreur = null;
      notifyListeners();

      // 1. Mise à jour dans le dépôt local (met à jour le cache local et tente la sync avec PocketBase)
      await _repo.modifier(clientId, body);

      // 2. Relecture immédiate du cache local mis à jour pour réactivité UI instantanée
      if (_atelierIdCourant != null) {
        final cacheFrais = await _repo.lireCache();
        clients = _versModeles(cacheFrais, _atelierIdCourant!);
        notifyListeners();
      }
    } catch (e) {
      erreur = 'Erreur lors de la modification : $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Méthode spécifique pour le RefreshIndicator de la vue
  Future<void> rafraichir() async {
    try {
      erreur = null;
      if (_atelierIdCourant == null) {
        final atelier = await atelierService.atelierCourant();
        _atelierIdCourant = atelier['id'] as String;
      }

      // Synchronise avec le serveur PocketBase
      await _repo.actualiser(filter: 'atelier = "$_atelierIdCourant"');

      // Lit le cache à jour
      final cacheFrais = await _repo.lireCache();
      clients = _versModeles(cacheFrais, _atelierIdCourant!);
      notifyListeners();
    } catch (e) {
      erreur = 'Erreur lors du rafraîchissement : $e';
      notifyListeners();
    }
  }

  /// Ajouter un nouveau client
  Future<void> ajouter(Map<String, dynamic> body) async {
    await _repo.creer(body);
  }

  /// Conversion et filtrage local
  List<ClientModel> _versModeles(
    List<Map<String, dynamic>> maps,
    String atelierId,
  ) {
    return maps
        .where((m) => m['atelier'] == atelierId)
        .map((m) => ClientModel.fromCacheMap(m))
        .toList()
      ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
  }

  @override
  void dispose() {
    _abonnementCache?.cancel();
    super.dispose();
  }
}
