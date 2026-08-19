import 'package:flutter/material.dart';
import 'package:teler_pro/outils/authservcice.dart';
import 'package:teler_pro/outils/themes.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final _nomAtelierCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  bool _envoiEnCours = false;
  String? _erreur;

  Future<void> _sInscrire() async {
    if (_motDePasseCtrl.text.length < 8) {
      setState(
        () => _erreur = 'Le mot de passe doit faire au moins 8 caractères',
      );
      return;
    }

    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });
    try {
      await authService.inscrire(
        email: _emailCtrl.text.trim(),
        motDePasse: _motDePasseCtrl.text,
        nomAtelier: _nomAtelierCtrl.text.trim().isEmpty
            ? 'Mon atelier'
            : _nomAtelierCtrl.text.trim(),
      );
      // AuthGate bascule automatiquement vers MainShell une fois connecté.
    } catch (e) {
      setState(() => _erreur = authService.messageErreur(e));
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
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
      appBar: AppBar(
        backgroundColor: KColors.ecru,
        elevation: 0,
        foregroundColor: KColors.ink,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Créer ton atelier',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: KColors.indigo,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nomAtelierCtrl,
                decoration: _decoration(
                  'Nom de l\'atelier (ex. Atelier Koffi)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration('Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _motDePasseCtrl,
                obscureText: true,
                decoration: _decoration('Mot de passe (8 caractères min.)'),
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
                onPressed: _envoiEnCours ? null : _sInscrire,
                child: _envoiEnCours
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Créer mon compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
