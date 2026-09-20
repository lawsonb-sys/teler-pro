import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/repo/offline_repo.dart';

class CommandesController extends ChangeNotifier {
  final _commandesRepo = OfflineRepository('commandes');
  final _paiementsRepo = OfflineRepository('paiements');

  String filtre = 'toutes';
  bool chargement = true;
  String? erreur;
  List<CommandeModel> commandes = [];

  /// Méthode dédiée pour afficher les commandes proprement dans le terminal
  void _imprimerCommandes(List<CommandeModel> commandes) {
    debugPrint(
      '\n=================== LISTE DES COMMANDES (${commandes.length}) ===================',
    );

    if (commandes.isEmpty) {
      debugPrint('Aucune commande disponible dans le cache.');
    } else {
      for (var i = 0; i < commandes.length; i++) {
        final c = commandes[i];
        debugPrint(
          '[${i + 1}] ID: ${c.id} | Client: ${c.clientNom} | Vêtement: ${c.typeVetement} | Statut: ${c.statut}',
        );
      }
    }

    debugPrint(
      '========================================================================\n',
    );
  }

  Future<void> charger() async {
    chargement = true;
    erreur = null;
    notifyListeners();

    try {
      final atelier = await atelierService.atelierCourant();
      final atelierId = atelier['id'] as String;
      // 1. Affichage immédiat de ce qui est déjà en cache (marche hors-ligne).
      final cache = await _commandesRepo.lireCache();
      final paiementsCache = await _paiementsRepo.lireCache();
      commandes = await _construireListe(cache, paiementsCache, atelierId);
      chargement = false;
      notifyListeners();

      // 2. Rafraîchissement en arrière-plan si le réseau est disponible.
      var filtreRequete = 'atelier = "$atelierId"';
      if (filtre != 'toutes') {
        filtreRequete += ' && statut = "$filtre"';
      }

      final frais = await _commandesRepo.actualiser(
        filter: filtreRequete,
        sort: 'date_livraison_prevue',
        expand: 'client',
        // Sans ça, le nom du client serait perdu une fois hors-ligne —
        // seul son ID resterait dans le cache.
        enrichir: (r) => {
          'client_nom':
              r.expand['client']?.firstOrNull?.getStringValue('nom') ?? '—',
        },
      );
      final paiementsFrais = await _paiementsRepo.actualiser();

      commandes = await _construireListe(frais, paiementsFrais, atelierId);
      notifyListeners();
    } catch (e) {
      erreur = 'Une erreur est survenue : $e';
      chargement = false;
      notifyListeners();
    }
  }

  Future<List<CommandeModel>> _construireListe(
    List<Map<String, dynamic>> commandesBrutes,
    List<Map<String, dynamic>> paiementsBruts,
    String atelierId,
  ) async {
    var filtrees = commandesBrutes.where((c) => c['atelier'] == atelierId);
    if (filtre != 'toutes') {
      filtrees = filtrees.where((c) => c['statut'] == filtre);
    }

    return filtrees.map((c) {
      final commandeId = c['id'] as String;
      final montantPaye = paiementsBruts
          .where((p) => p['commande'] == commandeId)
          .fold<double>(
            0,
            (s, p) => s + ((p['montant'] as num?)?.toDouble() ?? 0),
          );
      return CommandeModel.fromCacheMap(c, montantPaye: montantPaye);
    }).toList()..sort(
      (a, b) => (a.dateLivraisonPrevue ?? DateTime(2100)).compareTo(
        b.dateLivraisonPrevue ?? DateTime(2100),
      ),
    );
  }

  /*  Future<void> changerStatutCommande({
    required String id,
    required String statutActuel,
    required BuildContext context,
  }) async {
    final statuts = [
      {'code': 'attente', 'label': 'En attente'},
      {'code': 'en_cours', 'label': 'En cours'},
      {'code': 'pret', 'label': 'Prêt à livrer'},
      {'code': 'livre', 'label': 'Livré'},
    ];

    // La modal s'ouvre immédiatement sans aucune condition préalable
    final selection = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Changer le statut',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: KColors.indigo,
                ),
              ),
            ),
            const Divider(),
            ...statuts.map(
              (s) => ListTile(
                title: Text(s['label']!),
                trailing: statutActuel.toLowerCase() == s['code']
                    ? const Icon(Icons.check_circle, color: KColors.indigo)
                    : null,
                onTap: () => Navigator.pop(ctx, s['code']),
              ),
            ),
          ],
        ),
      ),
    );

    // Mise à jour de la base et notifications si une nouvelle option est choisie
    if (selection != null && selection != statutActuel) {
      await _commandesRepo.modifier(id, {'statut': selection});

      final index = commandes.indexWhere((c) => c.id == id);
      if (index != -1) {
        commandes[index] = commandes[index].copyWith(statut: selection);
      }

      notifyListeners();
    }
  }*/

  void changerFiltre(String nouveauFiltre) {
    if (filtre == nouveauFiltre) return;
    filtre = nouveauFiltre;
    charger();
  }
}
