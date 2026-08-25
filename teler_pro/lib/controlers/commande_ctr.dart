import 'package:flutter/foundation.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';

class CommandesController extends ChangeNotifier {
  String filtre = 'toutes';
  bool chargement = true;
  String? erreur;
  List<CommandeModel> commandes = [];

  Future<void> charger() async {
    chargement = true;
    erreur = null;
    notifyListeners();

    try {
      final atelier = await atelierService.atelierCourant();

      var filtreRequete = 'atelier = "${atelier.id}"';
      if (filtre != 'toutes') {
        filtreRequete += ' && statut = "$filtre"';
      }

      final records = await pb
          .collection('commandes')
          .getFullList(
            filter: filtreRequete,
            sort: 'date_livraison_prevue',
            expand: 'client',
          );

      final resultats = <CommandeModel>[];
      for (final r in records) {
        final paiements = await pb
            .collection('paiements')
            .getFullList(filter: 'commande = "${r.id}"');
        final montantPaye = paiements.fold<double>(
          0,
          (s, p) => s + (p.data['montant'] as num).toDouble(),
        );
        resultats.add(CommandeModel.fromRecord(r, montantPaye: montantPaye));
      }

      commandes = resultats;
    } catch (e) {
      erreur = 'Une erreur est survenue : $e';
    } finally {
      chargement = false;
      notifyListeners();
    }
  }

  /// Changer de filtre relance automatiquement le chargement avec le nouveau critère.
  void changerFiltre(String nouveauFiltre) {
    if (filtre == nouveauFiltre) return;
    filtre = nouveauFiltre;
    charger();
  }
}
