import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/services/connectivity_service.dart';

/// Gère, pour UNE collection PocketBase donnée (ex. "clients", "mesures",
/// "commandes", "paiements"), à la fois le cache local et la file d'attente
/// des créations/modifications qui n'ont pas pu partir tout de suite.
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

  /// [enrichir] permet d'ajouter des champs "aplatis" au cache à partir d'une
  /// relation développée (expand) — ex. le nom du client sur une commande,
  /// qui autrement ne serait pas lisible hors-ligne (seul l'ID est dans r.data).
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
          .getFullList(filter: filter, sort: sort, expand: expand);

      // ✅ Mettez à jour élément par élément
      for (final r in records) {
        final extra = enrichir != null ? enrichir(r) : <String, dynamic>{};

        // Si la réponse PocketBase contient 'expand', on extrait aussi les données enrichies automatiquement
        final Map<String, dynamic> expandData = {};
        if (r.expand.isNotEmpty) {
          r.expand.forEach((key, records) {
            // Dans le SDK PocketBase, records est toujours de type List<RecordModel>
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
    } catch (e) {
      // Le réseau semblait là mais la requête a échoué : on garde l'ancien cache tel quel.
    }
    return lireCache();
  }

  Future<void> creer(Map<String, dynamic> body) async {
    await _assurerInit();
    final connecte = await connectivityService.estConnecte();

    if (connecte) {
      try {
        final record = await pb.collection(collection).create(body: body);
        await _cacheBox.put(record.id, {...record.data, 'id': record.id});
        return;
      } catch (_) {}
    }

    final cleTemp = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    await _pendingBox.put(cleTemp, {'type': 'create', 'body': body});
    await _cacheBox.put(cleTemp, {...body, 'id': cleTemp, 'en_attente': true});
  }

  /* Future<void> modifier(String id, Map<String, dynamic> body) async {
    await _assurerInit();
    final connecte = await connectivityService.estConnecte();

    if (connecte) {
      try {
        final record = await pb.collection(collection).update(id, body: body);
        await _cacheBox.put(record.id, {...record.data, 'id': record.id});
        return;
      } catch (_) {}
    }

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
  }*/
  Future<void> modifier(String id, Map<String, dynamic> body) async {
    await _assurerInit();
    final connecte = await connectivityService.estConnecte();

    if (connecte) {
      try {
        print(
          '🌐 Tentative d\'envoi à PocketBase pour ID: $id avec data: $body',
        );
        final record = await pb.collection(collection).update(id, body: body);
        await _cacheBox.put(record.id, {...record.data, 'id': record.id});
        print('✅ Mis à jour sur PocketBase avec succès !');
        return;
      } catch (e) {
        print('❌ ERREUR POCKETBASE lors du update: $e');
        // Si tu veux qu'une erreur serveur (ex: 400 ou 403) stoppe l'exécution au lieu de passer en hors-ligne silencieux :
        rethrow;
      }
    }

    // Mode hors-ligne...
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
  }

  Future<void> synchroniser() async {
    await _assurerInit();
    if (_pendingBox.isEmpty) return;

    for (final cle in _pendingBox.keys.toList()) {
      final action = Map<String, dynamic>.from(_pendingBox.get(cle) as Map);
      final type = action['type'] as String?;
      final body = Map<String, dynamic>.from(action['body'] as Map);

      try {
        if (type == 'create') {
          final record = await pb.collection(collection).create(body: body);
          await _pendingBox.delete(cle);
          await _cacheBox.delete(cle);
          await _cacheBox.put(record.id, {...record.data, 'id': record.id});
        } else if (type == 'update') {
          final id = action['id'] as String;
          final record = await pb.collection(collection).update(id, body: body);
          await _pendingBox.delete(cle);
          await _cacheBox.put(record.id, {...record.data, 'id': record.id});
        }
      } catch (_) {}
    }
  }

  /// Supprime un enregistrement — directement si connecté, sinon mis en
  /// file d'attente. Dans les deux cas, il disparaît immédiatement du
  /// cache local (l'utilisateur ne doit plus le voir), même si la vraie
  /// suppression côté serveur n'a pas encore eu lieu.
  Future<void> supprimer(String id) async {
    await _assurerInit();
    final connecte = await connectivityService.estConnecte();

    // Un enregistrement encore temporaire (jamais synchronisé, "temp_...")
    // n'existe pas côté serveur : pas besoin de le mettre en file, on
    // annule juste sa création en attente et on l'efface du cache.
    if (id.startsWith('temp_')) {
      await _pendingBox.delete(id);
      await _cacheBox.delete(id);
      return;
    }

    if (connecte) {
      try {
        await pb.collection(collection).delete(id);
        await _cacheBox.delete(id);
        // Si une modification de ce même enregistrement était en attente,
        // elle n'a plus lieu d'être.
        await _pendingBox.delete('update_$id');
        return;
      } catch (_) {}
    }

    await _pendingBox.put('delete_$id', {'type': 'delete', 'id': id});
    await _cacheBox.delete(id); // disparaît de l'affichage tout de suite
  }

  Future<int> nombreEnAttente() async {
    await _assurerInit();
    return _pendingBox.length;
  }

  /// Permet à l'UI d'écouter les changements du cache en temps réel
  Stream<List<Map<String, dynamic>>> ecouterCache() async* {
    await _assurerInit();
    yield await lireCache();
    await for (final _ in _cacheBox.watch()) {
      yield await lireCache();
    }
  }

  /// Vides complètement le cache Hive pour cette collection
  Future<void> effacerCache() async {
    await _assurerInit();
    await _cacheBox.clear();
  }
}
