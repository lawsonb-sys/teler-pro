import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/authservcice.dart';
import 'package:teler_pro/pages/chargement.dart';
import 'package:teler_pro/pages/connexion/connexion.dart';
import 'package:teler_pro/pages/mainshell.dart';

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

  /// Vérifie la session locale d'abord (compatible hors-ligne)
  /// puis tente de rafraîchir le token si le réseau est disponible.
  Future<void> _verifierSession() async {
    // 1. Contrôle local : Si le token JWT stocké n'est pas/plus valide localement
    if (!pb.authStore.isValid) {
      pb.authStore.clear();
      if (mounted) setState(() => _etat = _EtatAuth.deconnecte);
      return;
    }

    // 2. L'utilisateur a un token valide en cache -> On le laisse entrer immédiatement
    if (mounted) setState(() => _etat = _EtatAuth.connecte);

    // 3. Tentative de rafraîchissement réseau en arrière-plan (sans bloquer l'UI)
    try {
      await pb.collection('users').authRefresh();
    } on ClientException catch (e) {
      // Si le serveur répond explicitement avec un code 401 ou 403 (Token révoqué ou expiré)
      if (e.statusCode == 401 || e.statusCode == 403) {
        pb.authStore.clear();
        if (mounted) setState(() => _etat = _EtatAuth.deconnecte);
      }
      // En cas d'erreur de connexion/réseau (statusCode == 0 ou timeout),
      // on ne fait rien : l'utilisateur conserve sa session locale.
    } catch (_) {
      // Autres erreurs inattendues : on ne déconnecte pas l'utilisateur s'il est hors-ligne
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
