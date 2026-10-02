import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/provider/repo_provider.dart';

part 'test_ctr.g.dart';

/// Données envoyées à la vue
typedef AccueilData = ({String nomAtelier, List<CommandeModel> commandes});

@riverpod
class AccueilController extends _$AccueilController {
  @override
  Future<AccueilData> build() async {
    // 1. Charger immédiatement le cache local
    final localData = await _lireDonneesCache();

    // 2. Mettre à jour depuis PocketBase en arrière-plan
    _synchroniser();

    return localData;
  }

  /// Lit Hive et associe chaque commande au nom de son client
  Future<AccueilData> _lireDonneesCache() async {
    final cacheAtelier = await ref.read(ateliersRepoProvider).lireCache();
    final cacheCommandes = await ref.read(commandesRepoProvider).lireCache();
    final cacheClients = await ref.read(clientsRepoProvider).lireCache();

    // 1. Nom de l'atelier
    final nomAtelier = cacheAtelier.isNotEmpty
        ? (cacheAtelier.first['nom']?.toString() ?? 'Mon Atelier')
        : 'Mon Atelier';

    // 2. Map rapide [ID_CLIENT -> NOM_CLIENT]
    final clientsMap = {
      for (var c in cacheClients)
        (c['id'] ?? c['id_client'] ?? '').toString():
            (c['nom'] ?? 'Client inconnu').toString(),
    };

    // 3. Transformation des commandes avec injection du nom du client
    final listCommandes = cacheCommandes.map((map) {
      final clientId = (map['client'] ?? map['client_id'] ?? '').toString();
      final mapModifiee = Map<String, dynamic>.from(map);

      // On prend d'abord le nom enrichi lors de la synchro, sinon on cherche dans la Map clients
      mapModifiee['clientNom'] =
          map['client_nom'] ?? clientsMap[clientId] ?? '—';

      return CommandeModel.fromCacheMap(mapModifiee);
    }).toList();

    return (nomAtelier: nomAtelier, commandes: listCommandes);
  }

  /// Synchronise PocketBase (avec les relations client)
  Future<void> _synchroniser() async {
    try {
      await Future.wait([
        ref.read(ateliersRepoProvider).actualiser(),
        ref.read(clientsRepoProvider).actualiser(),
      ]);

      // Synchronise les commandes en récupérant la relation 'client' (expand)
      await ref
          .read(commandesRepoProvider)
          .actualiser(
            expand: 'client',
            enrichir: (record) {
              final clientExpand = record.expand['client'];
              final clientNom =
                  (clientExpand != null && clientExpand.isNotEmpty)
                  ? clientExpand.first.data['nom']?.toString()
                  : null;
              return {'client_nom': clientNom};
            },
          );

      // Met à jour l'état avec les nouvelles données
      state = AsyncData(await _lireDonneesCache());
    } catch (e) {
      debugPrint('Erreur synchro accueil : $e');
    }
  }

  /// Action pour rafraîchir l'écran (Pull-to-refresh)
  Future<void> rafraichir() async {
    state = const AsyncLoading<AccueilData>().copyWithPrevious(state);
    await _synchroniser();
  }
}
