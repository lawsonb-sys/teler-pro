import 'package:pocketbase/pocketbase.dart';
import 'package:teler_pro/models/pocketbase.dart';

/// Récupère la ligne "ateliers" liée à l'utilisateur connecté.
/// Mise en cache en mémoire : évite de la redemander à chaque écran,
/// tant que la session ne change pas (voir AuthGate qui pourrait
/// réinitialiser ce cache à la déconnexion si besoin).
class AtelierService {
  RecordModel? _cache;

  Future<RecordModel> atelierCourant() async {
    if (_cache != null) return _cache!;

    final userId = pb.authStore.record!.id;
    final result = await pb
        .collection('ateliers')
        .getFirstListItem('user = "$userId"');
    _cache = result;
    return result;
  }

  void reinitialiserCache() => _cache = null;
}

final atelierService = AtelierService();
