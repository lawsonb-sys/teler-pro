import 'package:flutter/material.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/authservcice.dart';
import 'package:teler_pro/pages/chargement.dart';
import 'package:teler_pro/pages/connexion/connexion.dart';
import 'package:teler_pro/pages/mainshell.dart';

import 'package:flutter/material.dart';

enum _EtatAuth { chargement, connecte, deconnecte }

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  _EtatAuth _etat = _EtatAuth.chargement;

  @override
  void initState() {
    super.initState();
    _verifierSession();

    // Redessine cet écran à chaque connexion/déconnexion/expiration de session
    // survenant APRÈS ce premier chargement (ex. bouton "Se déconnecter").
    authService.ecouterChangements(() {
      if (mounted) {
        setState(
          () => _etat = authService.estConnecte
              ? _EtatAuth.connecte
              : _EtatAuth.deconnecte,
        );
      }
    });
  }

  /// Au lancement de l'app : si un token est stocké localement, on vérifie
  /// auprès du serveur qu'il est toujours valide (pas expiré/révoqué),
  /// plutôt que de faire confiance aveuglément au stockage local.
  Future<void> _verifierSession() async {
    if (!pb.authStore.isValid) {
      setState(() => _etat = _EtatAuth.deconnecte);
      return;
    }
    try {
      await pb.collection('users').authRefresh();
      if (mounted) setState(() => _etat = _EtatAuth.connecte);
    } catch (_) {
      // Token expiré ou révoqué côté serveur.
      pb.authStore.clear();
      if (mounted) setState(() => _etat = _EtatAuth.deconnecte);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_etat) {
      _EtatAuth.chargement => const ChargementPage(),
      _EtatAuth.connecte => const MainShell(),
      _EtatAuth.deconnecte => const ConnexionPage(),
    };
  }
}
