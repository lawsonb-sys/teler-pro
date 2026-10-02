import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/services/connectivity_service.dart';

/// Gère le cache local Hive et la file de synchronisation différée.
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

  Future<List<Map<String, dynamic>>> lireCache() async {
    await _assurerInit();
    return _cacheBox.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList();
  }

  Future<Map<String, dynamic>?> lireUnDuCache(String id) async {
    await _assurerInit();
    final v = _cacheBox.get(id);
    return v != null ? Map<String, dynamic>.from(v as Map) : null;
  }

  Future<List<Map<String, dynamic>>> actualiser({
    String? filter,
    String? sort,
    String? expand,
    Map<String, dynamic> Function(RecordModel)? enrichir,
  }) async {
    await _assurerInit();
    final connecte = await connectivityService.estConnecte();
    if (!connecte) return lireCache();

    try {
      final records = await pb
          .collection(collection)
          .getFullList(filter: filter, sort: sort, expand: expand)
          .timeout(const Duration(seconds: 3));

      for (final r in records) {
        final extra = enrichir != null ? enrichir(r) : <String, dynamic>{};

        final Map<String, dynamic> expandData = {};
        if (r.expand.isNotEmpty) {
          r.expand.forEach((key, records) {
            if (records.isNotEmpty) {
              final firstRecord = records.first;
              expandData['expand_$key'] = {
                ...firstRecord.data,
                'id': firstRecord.id,
              };
            }
          });
        }

        await _cacheBox.put(r.id, {
          ...r.data,
          'id': r.id,
          ...expandData,
          ...extra,
        });
      }
    } catch (_) {
      // Erreur réseau / Timeout : conservation du cache local
    }
    return lireCache();
  }

  /// ⚡ CRÉATION INSTANTANÉE (Write-Local-First)
  Future<Map<String, dynamic>> creer(Map<String, dynamic> body) async {
    await _assurerInit();
    final connecte = await connectivityService.estConnecte();

    // 1. Tenter un envoi en ligne si le réseau est disponible
    if (connecte) {
      try {
        final record = await pb
            .collection(collection)
            .create(body: body)
            .timeout(const Duration(seconds: 2));

        final Map<String, dynamic> donneeEnLigne = {
          ...record.data,
          'id': record.id,
        };
        await _cacheBox.put(record.id, donneeEnLigne);
        return donneeEnLigne;
      } catch (e) {
        // Serveur injoignable : bascule automatique vers le mode hors-ligne
      }
    }

    // 2. Mode hors-ligne : génération de l'objet temporaire complet
    final cleTemp = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, dynamic> objetLocal = {
      ...body,
      'id': cleTemp,
      'en_attente': true,
      'created': DateTime.now().toIso8601String(),
    };

    await _pendingBox.put(cleTemp, {'type': 'create', 'body': body});
    await _cacheBox.put(cleTemp, objetLocal);

    // 💡 IMPORTANT : Retourne l'objet complet au lieu d'une Map vide `{}` !
    return objetLocal;
  }

  /// ⚡ MODIFICATION SÉCURISÉE AVEC TIMEOUT ET FALLBACK HORS-LIGNE
  Future<Map<String, dynamic>> modifier(
    String id,
    Map<String, dynamic> body,
  ) async {
    await _assurerInit();
    final connecte = await connectivityService.estConnecte();

    if (connecte) {
      try {
        final record = await pb
            .collection(collection)
            .update(id, body: body)
            .timeout(const Duration(seconds: 2));

        final existant = _cacheBox.get(id);
        final Map<String, dynamic> ancienCache = existant != null
            ? Map<String, dynamic>.from(existant as Map)
            : {};

        final cacheFusionne = {...ancienCache, ...record.data, 'id': record.id};

        await _cacheBox.put(record.id, cacheFusionne);
        return cacheFusionne;
      } catch (e) {
        // En cas de timeout ou PocketBase indisponible -> Suite du code
      }
    }

    // Mode hors-ligne
    await _pendingBox.put('update_$id', {
      'type': 'update',
      'id': id,
      'body': body,
    });

    final existant = _cacheBox.get(id);
    final fusionne = {
      if (existant != null) ...Map<String, dynamic>.from(existant as Map),
      ...body,
      'id': id,
      'en_attente': true,
    };

    await _cacheBox.put(id, fusionne);
    return fusionne;
  }

  /// ⚡ SYNCHRONISATION COMPLETE
  Future<void> synchroniser() async {
    await _assurerInit();
    if (_pendingBox.isEmpty) return;

    for (final cle in _pendingBox.keys.toList()) {
      final action = Map<String, dynamic>.from(_pendingBox.get(cle) as Map);
      final type = action['type'] as String?;
      final body = action['body'] != null
          ? Map<String, dynamic>.from(action['body'] as Map)
          : null;

      try {
        if (type == 'create' && body != null) {
          final record = await pb
              .collection(collection)
              .create(body: body)
              .timeout(const Duration(seconds: 3));

          await _pendingBox.delete(cle);
          await _cacheBox.delete(cle);
          await _cacheBox.put(record.id, {...record.data, 'id': record.id});
        } else if (type == 'update' && body != null) {
          final id = action['id'] as String;
          final record = await pb
              .collection(collection)
              .update(id, body: body)
              .timeout(const Duration(seconds: 3));

          await _pendingBox.delete(cle);

          final existant = _cacheBox.get(id);
          final Map<String, dynamic> ancienCache = existant != null
              ? Map<String, dynamic>.from(existant as Map)
              : {};

          await _cacheBox.put(record.id, {
            ...ancienCache,
            ...record.data,
            'id': record.id,
          });
        } else if (type == 'delete') {
          final id = action['id'] as String;
          await pb
              .collection(collection)
              .delete(id)
              .timeout(const Duration(seconds: 3));

          await _pendingBox.delete(cle);
        }
      } catch (_) {
        // Échec de la tentative -> Reste dans _pendingBox pour le prochain cycle
      }
    }
  }

  Future<void> supprimer(String id) async {
    await _assurerInit();
    final connecte = await connectivityService.estConnecte();

    if (id.startsWith('temp_')) {
      await _pendingBox.delete(id);
      await _cacheBox.delete(id);
      return;
    }

    if (connecte) {
      try {
        await pb
            .collection(collection)
            .delete(id)
            .timeout(const Duration(seconds: 2));

        await _cacheBox.delete(id);
        await _pendingBox.delete('update_$id');
        return;
      } catch (_) {}
    }

    await _pendingBox.put('delete_$id', {'type': 'delete', 'id': id});
    await _cacheBox.delete(id);
  }

  Future<int> nombreEnAttente() async {
    await _assurerInit();
    return _pendingBox.length;
  }

  Stream<List<Map<String, dynamic>>> ecouterCache() async* {
    await _assurerInit();
    yield await lireCache();
    await for (final _ in _cacheBox.watch()) {
      yield await lireCache();
    }
  }

  Future<void> effacerCache() async {
    await _assurerInit();
    await _cacheBox.clear();
  }
}
