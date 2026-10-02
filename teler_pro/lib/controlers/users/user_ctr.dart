import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:teler_pro/provider/repo_provider.dart';

import '../../models/pocketbase.dart';
import '../../repo/offline_repo.dart';

class AtelierUserData {
  final Map<String, dynamic> user;
  final Map<String, dynamic> atelier;

  AtelierUserData({
    required this.user,
    required this.atelier,
  });
}

class AtelierUserNotifier extends AsyncNotifier<AtelierUserData> {
  final _ateliersRepo = OfflineRepository('ateliers');
  final _usersRepo = OfflineRepository('users');

  @override
  FutureOr<AtelierUserData> build() {
    return _charger();
  }

  Future<AtelierUserData> _charger() async {
    final record = pb.authStore.record;
    final userId = record?.id;
    if (userId == null) {
      throw Exception("Utilisateur non connecté");
    }

    // 1. Utilisateur
    Map<String, dynamic> userdata = record?.toJson() ?? {};
    final usercache = await _usersRepo.lireCache();
    final userlocal = usercache.firstWhere(
          (u) => u['id'] == userId,
      orElse: () => userdata,
    );
    if (userlocal.isNotEmpty) {
      userdata = userlocal;
    }

    // 2. Atelier (Correction de la fallback sur {})
    final atelierCache = await _ateliersRepo.lireCache();
    final atelierlocale = atelierCache.firstWhere(
          (a) => a['user'] == userId,
      orElse: () => {}, // 👈 Corrige : renvoie une Map vide si non trouvé
    );

    // Si trouvé en local (Cache-first)
    if (atelierlocale.isNotEmpty) {
      // Synchronisation réseau silencieuse
      _ateliersRepo.actualiser(filter: 'user = "$userId"').then((_) async {
        final nouveauCache = await _ateliersRepo.lireCache();
        final atelierMisAJour = nouveauCache.firstWhere(
              (a) => a['user'] == userId,
          orElse: () => {},
        );

        if (atelierMisAJour.isNotEmpty) {
          // 💡 Sécurité Flutter : différer la mise à jour de state au prochain frame
          Future.microtask(() {
            state = AsyncData(
              AtelierUserData(user: userdata, atelier: atelierMisAJour),
            );
          });
        }
      }).catchError((_) {});

      return AtelierUserData(user: userdata, atelier: atelierlocale);
    }

    // 3. Premier démarrage (Fetch réseau obligatoire si cache vide)
    await _ateliersRepo.actualiser(filter: 'user = "$userId"');
    await _usersRepo.actualiser(filter: 'id = "$userId"');

    final cacheAteliersFrais = await _ateliersRepo.lireCache();
    final cacheUsersFrais = await _usersRepo.lireCache();

    final finalAtelier = cacheAteliersFrais.firstWhere(
          (a) => a['user'] == userId,
      orElse: () => throw Exception("Aucun atelier trouvé pour cet utilisateur."),
    );

    final finalUser = cacheUsersFrais.firstWhere(
          (u) => u['id'] == userId,
      orElse: () => userdata,
    );

    return AtelierUserData(user: finalUser, atelier: finalAtelier);
  }

  Future<void> modifier(String atelierid,String userID, Map<String, dynamic> body,Map<String, dynamic> bodyuser,File nvImage) async {
    await _ateliersRepo.modifierTexte(atelierid, body);
    List<http.MultipartFile> files = [];
    if(nvImage != null){
      files.add(await http.MultipartFile.fromPath('avatar', nvImage.path));
    }
    await _usersRepo.modifierAvecPhotos(userID, bodyuser,files: files, photos: []);
    await rafraichir(); // Recharger l'état réactif après modification
    ref.read(syncManagerProvider.notifier).synchronizeCollections();

  }
  // Future<void> supprimer(String atelierid) async {
  //   await _ateliersRepo.supprimer(atelierid);
  //   ref.invalidateSelf();
  //   await rafraichir(); // Recharger l'état réactif après modification
  //   ref.read(syncManagerProvider.notifier).synchronizeCollections();
  // }
  /// Rafraîchir manuellement les données
  Future<void> rafraichir() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _charger());
  }

  /// Réinitialiser et effacer le cache lors de la déconnexion
  Future<void> reinitialiserCache() async {
    await _ateliersRepo.effacerCache();
    await _usersRepo.effacerCache();
    ref.invalidateSelf();
  }
}

// 💡 Provider Global
final atelierUserProvider =
AsyncNotifierProvider<AtelierUserNotifier, AtelierUserData>(
  AtelierUserNotifier.new,
);