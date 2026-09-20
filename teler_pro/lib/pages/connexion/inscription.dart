import 'package:flutter/material.dart';
import 'package:teler_pro/controlers/connexion_ctr.dart';

import 'package:teler_pro/outils/themes.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final _nomAtelierCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nomUtilisateurCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  final _controller = ConnexionControloler();
  final _ville = TextEditingController();
  final _telephone = TextEditingController();

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
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (BuildContext context, Widget? child) {
                return Column(
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
                      controller: _nomUtilisateurCtrl,
                      decoration: _decoration('Nom d\'utilisateur'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _decoration('Email'),
                    ),
                    TextField(
                      controller: _telephone,
                      decoration: _decoration('Numero'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _ville,
                      decoration: _decoration('Ville'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _motDePasseCtrl,
                      obscureText: true,
                      decoration: _decoration(
                        'Mot de passe (8 caractères min.)',
                      ),
                    ),
                    if (_controller.erreur != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _controller.erreur!,
                        style: const TextStyle(
                          color: KColors.terracotta,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _controller.envoiEnCours
                          ? null
                          : () {
                              _controller.sInscrire(
                                _emailCtrl.text.trim(),
                                _motDePasseCtrl.text.trim(),
                                _nomAtelierCtrl.text.trim(),
                                _nomUtilisateurCtrl.text.trim(),
                                _ville.text.trim(),
                                _telephone.text.trim(),
                              );
                            },

                      child: _controller.envoiEnCours
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
