import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teler_pro/repo/offline_repo.dart';
part 'repo_provider.g.dart';

@riverpod
OfflineRepository commandesRepo(Ref ref) => OfflineRepository('commandes');
@riverpod
OfflineRepository ateliersRepo(Ref ref) => OfflineRepository('ateliers');
@riverpod
OfflineRepository clientsRepo(Ref ref) => OfflineRepository('clients');

@riverpod
class SyncManager extends _$SyncManager {
  @override
  Future<void> build() async {
    // Initialisation du manager de synchronisation
    // Vous pouvez ajouter ici toute logique d'initialisation nécessaire
  }

  Future<void> synchronizeCollections() async {
    final collections = ['commandes', 'ateliers', 'clients'];
    for (final collection in collections) {
      final repo = OfflineRepository(collection);
      await repo.synchroniser();
      await repo.actualiser();
    }
  }
}
