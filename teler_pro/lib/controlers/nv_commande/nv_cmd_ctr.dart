import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teler_pro/controlers/command_ctr/commande_ctr.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';
import 'package:teler_pro/provider/repo_provider.dart';
import 'package:teler_pro/provider/test_ctr.dart';
import 'package:teler_pro/repo/offline_repo.dart';

part 'nv_cmd_ctr.g.dart';

@riverpod
class NouvelleCommandeController extends _$NouvelleCommandeController {
  final _commandesRepo = OfflineRepository('commandes');
  final _paiementsRepo = OfflineRepository('paiements');

  String keyList(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(
      length,
          (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String get newcmdId => keyList(15);

  @override
  FutureOr<List<ClientModel>> build() async {
    final atelier = await atelierService.atelierCourant();
    final cache = await OfflineRepository('clients').lireCache();
    return cache
        .where((c) => c['atelier'] == atelier['id'])
        .map((c) => ClientModel.fromCacheMap(c))
        .toList();
  }

  Future<Map<String, dynamic>> creerCommande({
    required String clientId,
    required String clientNom,
    required String typeVetement,
    required DateTime dateLivraison,
    required double prixTotal,
    required double acompte,
    String? tissu,
    List<File> photos = const [], // 👈 Liste de fichiers images venant de l'IHM
  }) async {
    final atelier = await atelierService.atelierCourant();

    // 1. Appel de `_commandesRepo.creer` avec le paramètre `photosLocal`
    final commandeCreated = await _commandesRepo.creer(
      {
        'atelier': atelier['id'],
        'client': clientId,
        'clientNom': clientNom,
        'type_vetement': typeVetement,
        'tissu': tissu,
        'prix_total': prixTotal,
        'statut': 'attente',
        'date_livraison_prevue':
        dateLivraison.toIso8601String().split('T').first,
      },
      photosLocal: photos, // 👈 Les objets File sont gérés directement par OfflineRepository
      nomChampFichier: 'photos', // 👈 Nom du champ File dans PocketBase
    );

    // 2. Création de l'acompte si présent
    if (acompte > 0 && commandeCreated['id'] != null) {
      await _paiementsRepo.creer({
        'commande': commandeCreated['id'],
        'montant': acompte,
        'mode': 'especes',
      });
    }

    if (!ref.mounted) return commandeCreated;

    // 3. Déclenchement de la synchronisation en tâche de fond
    ref.read(syncManagerProvider.notifier).synchronizeCollections();

    return commandeCreated;
  }
}