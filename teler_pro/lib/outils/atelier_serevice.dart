import 'package:teler_pro/models/pocketbase.dart';

import 'package:teler_pro/repo/offline_repo.dart';

class AtelierService {
  final _repo = OfflineRepository('ateliers');

  /// Récupère l'atelier courant de manière sécurisée (cache en priorité, réseau en arrière-plan)
  Future<Map<String, dynamic>> atelierCourant() async {
    final userId = pb.authStore.record?.id;
    if (userId == null) {
      throw Exception("Utilisateur non connecté");
    }

    // 1. Lire immédiatement depuis le cache Hive local
    final cache = await _repo.lireCache();
    final atelierLocal = cache.firstWhere(
      (a) => a['user'] == userId,
      orElse: () => {},
    );

    // Si trouvé en local, on le renvoie tout de suite (marche 100% hors-ligne)
    if (atelierLocal.isNotEmpty) {
      // Tente d'actualiser en arrière-plan sans bloquer si le réseau est dispo
      _repo.actualiser(filter: 'user = "$userId"');
      return atelierLocal;
    }

    // 2. Premier démarrage (cache vide) : Fetch réseau obligatoire
    await _repo.actualiser(filter: 'user = "$userId"');
    final cacheFrais = await _repo.lireCache();

    return cacheFrais.firstWhere(
      (a) => a['user'] == userId,
      orElse: () =>
          throw Exception("Aucun atelier trouvé pour cet utilisateur."),
    );
  }

  /// Vide le cache de l'atelier lors de la déconnexion
  Future<void> reinitialiserCache() async {
    await _repo.effacerCache();
  }
}

final atelierService = AtelierService();
