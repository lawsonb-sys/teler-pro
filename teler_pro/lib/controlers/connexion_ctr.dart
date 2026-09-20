import 'package:flutter/material.dart';
import 'package:teler_pro/outils/authservcice.dart';

class ConnexionControloler extends ChangeNotifier {
  // Add your controller logic here
  bool envoiEnCours = false;
  String? erreur;
  Future<bool> seConnecter(String email, String motDePasse) async {
    envoiEnCours = true;
    erreur = null;
    notifyListeners();

    try {
      // Simulate a network request or authentication logic
      await authService.connecter(email: email, motDePasse: motDePasse);
      return true; // Return true if successful
      // If successful, you can navigate to the next page or update the state
    } catch (e) {
      erreur = authService.messageErreur(e);
      return false; // Return false if unsuccessful
    } finally {
      envoiEnCours = false;
      notifyListeners();
    }
  }

  Future<bool> sInscrire(
    String email,
    String motDePasse,
    String nomAtelier,
    String nom,
    String ville,
    String telephone,
  ) async {
    envoiEnCours = true;
    erreur = null;
    notifyListeners();

    try {
      // Simulate a network request or authentication logic
      await authService.inscrire(
        email: email,
        motDePasse: motDePasse,
        nomAtelier: nomAtelier,
        nom: nom,
        telephone: telephone,
        ville: ville,
      );
      return true; // Return true if successful
      // If successful, you can navigate to the next page or update the state
    } catch (e) {
      erreur = authService.messageErreur(e);
      return false; // Return false if unsuccessful
    } finally {
      envoiEnCours = false;
      notifyListeners();
    }
  }
}
