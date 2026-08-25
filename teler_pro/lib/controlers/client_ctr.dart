import 'package:flutter/foundation.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';
import 'package:teler_pro/repo/offline_repo.dart';

class ClientsController extends ChangeNotifier {
  final _repo = OfflineRepository('clients');

  bool chargement = true;
  String? erreur;
  List<ClientModel> clients = [];

  Future<void> charger() async {
    chargement = true;
    erreur = null;
    notifyListeners();

    try {
      final atelier = await atelierService.atelierCourant();

      // 1. Affichage immédiat de ce qu'on a déjà en cache (marche même hors-ligne).
      final cache = await _repo.lireCache();
      clients = _versModeles(cache, atelier.id);
      chargement = false;
      notifyListeners();

      // 2. En parallèle, tentative de rafraîchissement depuis le serveur —
      // ne bloque plus l'affichage puisque le cache est déjà montré.
      final frais = await _repo.actualiser(
        filter: 'atelier = "${atelier.id}"',
        sort: 'nom',
      );
      clients = _versModeles(frais, atelier.id);
      notifyListeners();
    } catch (e) {
      erreur = 'Une erreur est survenue : $e';
      chargement = false;
      notifyListeners();
    }
  }

  Future<void> ajouter(Map<String, dynamic> body) async {
    await _repo.creer(body);
    await charger(); // réaffiche la liste, avec la nouvelle entrée incluse
  }

  List<ClientModel> _versModeles(
    List<Map<String, dynamic>> maps,
    String atelierId,
  ) {
    return maps
        .where(
          (m) => m['atelier'] == atelierId,
        ) // le cache peut contenir plusieurs ateliers si jamais réutilisé
        .map((m) => ClientModel.fromCacheMap(m))
        .toList()
      ..sort((a, b) => a.nom.compareTo(b.nom));
  }
}
