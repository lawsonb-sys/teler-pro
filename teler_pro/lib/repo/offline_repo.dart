import 'package:hive_flutter/hive_flutter.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/services/connectivity_service.dart';

/// Gère, pour UNE collection PocketBase donnée (ex. "clients"), à la fois :
/// - le cache local (consultable même sans réseau)
/// - la file d'attente des créations qui n'ont pas pu partir tout de suite
///
/// Un seul de ces objets par collection suffit — voir ClientsController
/// pour un exemple d'utilisation complet.
class OfflineRepository {
  final String collection;
  late Box _cacheBox;
  late Box _pendingBox;
  bool _initialise = false;

  OfflineRepository(this.collection);

  Future<void> _assurerInit() async {
    if (_initialise) return;
    _cacheBox = await Hive.openBox('cache_$collection');
    _pendingBox = await Hive.openBox('pending_$collection');
    _initialise = true;
  }

  /// Ce qui est déjà en cache — utilisable immédiatement, même hors-ligne.
  Future<List<Map<String, dynamic>>> lireCache() async {
    await _assurerInit();
    return _cacheBox.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  /// Tente de rafraîchir depuis PocketBase ; retombe silencieusement sur le
  /// cache local si pas de réseau ou si le serveur ne répond pas.
  Future<List<Map<String, dynamic>>> actualiser({
    String? filter,
    String? sort,
    String? expand,
  }) async {
    await _assurerInit();
    final connecte = await connectivityService.estConnecte();
    if (!connecte) return lireCache();

    try {
      final records = await pb
          .collection(collection)
          .getFullList(filter: filter, sort: sort, expand: expand);
      await _cacheBox.clear();
      for (final r in records) {
        await _cacheBox.put(r.id, {...r.data, 'id': r.id});
      }
    } catch (_) {
      // Le réseau semblait là mais la requête a échoué : on garde l'ancien cache tel quel.
    }
    return lireCache();
  }

  /// Crée un enregistrement — directement si connecté, sinon mis en file
  /// d'attente ET ajouté au cache local tout de suite (affichage immédiat,
  /// même si la vraie synchronisation n'a pas encore eu lieu).
  Future<void> creer(Map<String, dynamic> body) async {
    await _assurerInit();
    final connecte = await connectivityService.estConnecte();

    if (connecte) {
      try {
        final record = await pb.collection(collection).create(body: body);
        await _cacheBox.put(record.id, {...record.data, 'id': record.id});
        return;
      } catch (_) {
        // Échec malgré la connexion apparente : on tombe dans la mise en attente.
      }
    }

    final cleTemp = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    await _pendingBox.put(cleTemp, body);
    // Affichage optimiste : visible tout de suite dans l'UI, même non-synchronisé.
    await _cacheBox.put(cleTemp, {...body, 'id': cleTemp, 'en_attente': true});
  }

  /// Rejoue toute la file d'attente. À appeler dès que la connexion revient.
  Future<void> synchroniser() async {
    await _assurerInit();
    if (_pendingBox.isEmpty) return;

    for (final cle in _pendingBox.keys.toList()) {
      final body = Map<String, dynamic>.from(_pendingBox.get(cle) as Map);
      try {
        final record = await pb.collection(collection).create(body: body);
        await _pendingBox.delete(cle);
        await _cacheBox.delete(
          cle,
        ); // retire la version temporaire "en_attente"
        await _cacheBox.put(record.id, {...record.data, 'id': record.id});
      } catch (_) {
        // reste en attente pour la prochaine tentative
      }
    }
  }

  Future<int> nombreEnAttente() async {
    await _assurerInit();
    return _pendingBox.length;
  }
}
