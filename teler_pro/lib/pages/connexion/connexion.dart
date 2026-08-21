import 'package:flutter/material.dart';
import 'package:teler_pro/outils/authservcice.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/pages/connexion/inscription.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _emailCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  bool _envoiEnCours = false;
  String? _erreur;
  bool _motDePasseVisible = false;

  Future<void> _seConnecter() async {
    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });
    try {
      await authService.connecter(
        email: _emailCtrl.text.trim(),
        motDePasse: _motDePasseCtrl.text,
      );
      // Pas de navigation manuelle ici : AuthGate détecte le changement
      // via pb.authStore.onChange et bascule automatiquement vers MainShell.
    } catch (e) {
      setState(() => _erreur = authService.messageErreur(e));
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    suffixIcon: label == 'Mot de passe'
        ? IconButton(
            onPressed: () {
              print("Eye pressed");
              setState(() {
                _motDePasseVisible = !_motDePasseVisible;
              });
              print("Eye pressed $_motDePasseVisible");
            },
            icon: Icon(
              _motDePasseVisible ? Icons.visibility : Icons.visibility_off,
              size: 24,
            ),
          )
        : null,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: KColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: KColors.cardBorder),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.ecru,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Teler Pro',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: KColors.indigo,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'L\'atelier dans la poche',
                style: TextStyle(fontSize: 13, color: KColors.muted),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration('Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _motDePasseCtrl,
                obscureText: _motDePasseVisible,
                decoration: _decoration('Mot de passe'),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 10),
                Text(
                  _erreur!,
                  style: const TextStyle(
                    color: KColors.terracotta,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _envoiEnCours ? null : _seConnecter,
                child: _envoiEnCours
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Se connecter'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InscriptionPage()),
                ),
                child: const Text(
                  'Créer un compte',
                  style: TextStyle(color: KColors.indigo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
