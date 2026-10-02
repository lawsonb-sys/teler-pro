import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/services/connectivity_service.dart';

import '../outils/dialogue.dart';
import '../outils/pockethealth.dart';

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

    // 1. Récupère les IDs qui sont en attente de suppression
    final idsEnSuppression = _pendingBox.keys
        .where((k) => k.toString().startsWith('delete_'))
        .map((k) => k.toString().replaceFirst('delete_', ''))
        .toSet();

    // 2. Renvoie uniquement les éléments du cache qui ne sont pas en attente de suppression
    return _cacheBox.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .where((item) => !idsEnSuppression.contains(item['id']))
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

  /// ⚡ CRÉATION INSTANTANÉE (Multi-images / Write-Local-First)
  Future<Map<String, dynamic>> creer(
      Map<String, dynamic> body, {
        List<File> photosLocal = const [],
        String nomChampFichier = 'photos',
      }) async {
    await _assurerInit();
    final connecte = await connectivityService.estConnecte();

    // Extraire les chemins locaux
    final List<String> cheminsLocaux = [];
    for (final f in photosLocal) {
      if (await f.exists()) {
        cheminsLocaux.add(f.path);
      }
    }

    // 1. Tenter un envoi en ligne si le réseau est disponible
    if (connecte) {
      try {
        final List<http.MultipartFile> files = [];
        for (final path in cheminsLocaux) {
          files.add(
            await http.MultipartFile.fromPath(nomChampFichier, path),
          );
        }

        final record = await pb
            .collection(collection)
            .create(body: body, files: files)
            .timeout(const Duration(seconds: 8));

        final Map<String, dynamic> donneeEnLigne = {
          ...record.data,
          'id': record.id,
          'en_attente': false,
        };
        await _cacheBox.put(record.id, donneeEnLigne);
        return donneeEnLigne;
      } catch (e) {
        print('Échec en ligne pour création, bascule hors-ligne : $e');
      }
    }

    // 2. Mode hors-ligne : génération de l'objet temporaire
    final cleTemp = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, dynamic> objetLocal = {
      ...body,
      'id': cleTemp,
      nomChampFichier: cheminsLocaux, // Conserve les chemins locaux pour affichage direct
      'en_attente': true,
      'created': DateTime.now().toIso8601String(),
    };

    await _pendingBox.put(cleTemp, {
      'type': 'create',
      'body': body,
      'nom_champ_fichier': nomChampFichier,
      'local_file_paths': cheminsLocaux,
    });

    await _cacheBox.put(cleTemp, objetLocal);
    return objetLocal;
  }

  /// ⚡ MODIFICATION SÉCURISÉE (Multi-images, Timeout & Fallback)
  /// 1. MODIFICATION SIMPLE (Données texte uniquement)
  Future<Map<String, dynamic>> modifierTexte(
      String id,
      Map<String, dynamic> body,
      ) async {
    await _assurerInit();
    final connecte = await connectivityService.estConnecte();

    // 1. Envoi direct si connecté
    if (connecte) {
      try {
        final record = await pb
            .collection(collection)
            .update(id, body: body)
            .timeout(const Duration(seconds: 5));

        final cacheActuel = await lireUnDuCache(id) ?? {};
        final cacheFusionne = {
          ...cacheActuel,
          ...record.data,
          'id': record.id,
          'en_attente': false,
        };

        await _cacheBox.put(record.id, cacheFusionne);
        await _pendingBox.delete('update_$id');
        return cacheFusionne;
      } catch (e) {
        print('Échec en ligne (texte), bascule hors-ligne : $e');
      }
    }

    // 2. Fallback Hors-Ligne
    await _pendingBox.put('update_$id', {
      'type': 'update',
      'id': id,
      'body': body,
    });

    final cacheActuel = await lireUnDuCache(id) ?? {};
    final fusionne = {
      ...cacheActuel,
      ...body,
      'id': id,
      'en_attente': true,
    };

    await _cacheBox.put(id, fusionne);
    return fusionne;
  }

  /// 2. MODIFICATION AVEC PHOTOS (Support multi-images)
  Future<Map<String, dynamic>> modifierAvecPhotos(
      String id,
      Map<String, dynamic> body, {
        required List<File> photos,
        String nomChampFichier = 'photos', required List<http.MultipartFile> files,
      }) async {
    await _assurerInit();
    final connecte = await connectivityService.estConnecte();

    // Vérification et récupération des chemins valides
    final List<String> cheminsLocaux = [];
    for (final f in photos) {
      if (await f.exists()) {
        cheminsLocaux.add(f.path);
      }
    }

    // 1. Envoi direct si connecté
    if (connecte) {
      try {
        final List<http.MultipartFile> files = [];
        for (final path in cheminsLocaux) {
          files.add(
            await http.MultipartFile.fromPath(nomChampFichier, path),
          );
        }

        final record = await pb
            .collection(collection)
            .update(id, body: body, files: files)
            .timeout(const Duration(seconds: 8));

        final cacheActuel = await lireUnDuCache(id) ?? {};
        final cacheFusionne = {
          ...cacheActuel,
          ...record.data,
          'id': record.id,
          'en_attente': false,
        };

        await _cacheBox.put(record.id, cacheFusionne);
        await _pendingBox.delete('update_$id');
        return cacheFusionne;
      } catch (e) {
        print('Échec en ligne (photos), bascule hors-ligne : $e');
      }
    }

    // 2. Fallback Hors-Ligne
    await _pendingBox.put('update_$id', {
      'type': 'update',
      'id': id,
      'body': body,
      'nom_champ_fichier': nomChampFichier,
      'local_file_paths': cheminsLocaux,
    });

    final cacheActuel = await lireUnDuCache(id) ?? {};
    final fusionne = {
      ...cacheActuel,
      ...body,
      if (cheminsLocaux.isNotEmpty) nomChampFichier: cheminsLocaux,
      'id': id,
      'en_attente': true,
    };

    await _cacheBox.put(id, fusionne);
    return fusionne;
  }
  /// ⚡ SYNCHRONISATION COMPLÈTE HORS-LIGNE -> EN LIGNE (Support Multi-fichiers)
  Future<void> synchroniser() async {
    await _assurerInit();
    if (_pendingBox.isEmpty) return;

    // 1. Vérification réseau
    final serveurOK = await pb.estServeurAccessible();
    if (!serveurOK) return;

    // 2. Traitement séquentiel
    final cles = _pendingBox.keys.toList();

    for (final cle in cles) {
      if (!_pendingBox.containsKey(cle)) continue;

      final action = Map<String, dynamic>.from(_pendingBox.get(cle) as Map);
      final type = action['type'] as String?;
      final body = action['body'] != null
          ? Map<String, dynamic>.from(action['body'] as Map)
          : null;

      final nomChampFichier = (action['nom_champ_fichier'] as String?) ?? 'photos';

      // Extraction de la liste des fichiers locaux (support rétro-compatible avec single file)
      final List<String> localFilePaths = [];
      if (action['local_file_paths'] != null) {
        localFilePaths.addAll(List<String>.from(action['local_file_paths'] as List));
      } else if (action['local_file_path'] != null) {
        localFilePaths.add(action['local_file_path'] as String);
      }

      // Préparation des MultipartFile
      final List<http.MultipartFile> files = [];
      for (final path in localFilePaths) {
        final file = File(path);
        if (await file.exists()) {
          files.add(
            await http.MultipartFile.fromPath(nomChampFichier, path),
          );
        }
      }

      try {
        if (type == 'create' && body != null) {
          final record = await pb
              .collection(collection)
              .create(body: body, files: files)
              .timeout(const Duration(seconds: 8));

          await _pendingBox.delete(cle);

          if (cle.toString().startsWith('temp_')) {
            await _cacheBox.delete(cle);
          }

          await _cacheBox.put(record.id, {
            ...record.data,
            'id': record.id,
            'en_attente': false,
          });

        } else if (type == 'update' && body != null) {
          final id = action['id'] as String;

          if (id.startsWith('temp_')) continue;

          final record = await pb
              .collection(collection)
              .update(id, body: body, files: files)
              .timeout(const Duration(seconds: 8));

          await _pendingBox.delete(cle);

          final existant = _cacheBox.get(id);
          final Map<String, dynamic> ancienCache = existant != null
              ? Map<String, dynamic>.from(existant as Map)
              : {};

          await _cacheBox.put(record.id, {
            ...ancienCache,
            ...record.data,
            'id': record.id,
            'en_attente': false,
          });

        } else if (type == 'delete') {
          final id = action['id'] as String;

          if (!id.startsWith('temp_')) {
            await pb
                .collection(collection)
                .delete(id)
                .timeout(const Duration(seconds: 5));
          }

          await _pendingBox.delete(cle);
          await _cacheBox.delete(id);
        }

      } on ClientException catch (e) {
        if (e.statusCode == 400 || e.statusCode == 404) {
          print('⚠️ Action invalide $cle (Code ${e.statusCode}) : ${e.response["message"]}. Action supprimée.');
          await _pendingBox.delete(cle);
        } else {
          print('🔴 Erreur serveur/réseau pour $cle : $e. Interruption.');
          break;
        }
      } catch (e) {
        print('🔴 Échec de la synchro pour $cle : $e. Interruption.');
        break;
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
            .timeout(const Duration(seconds: 5));

        await _cacheBox.delete(id);
        await _pendingBox.delete('update_$id');
        await _pendingBox.delete('delete_$id');
        return;
      } catch (_) {}
    }

    await _pendingBox.put('delete_$id', {'type': 'delete', 'id': id});
    await _pendingBox.delete('update_$id');
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