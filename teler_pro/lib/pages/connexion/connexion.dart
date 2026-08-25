import 'package:flutter/material.dart';
import 'package:teler_pro/controlers/connexion_ctr.dart';
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
  bool _motDePasseVisible = false;
  final _controller = ConnexionControloler();
  @override
  void dispose() {
    _controller.dispose();
    _emailCtrl.dispose();
    _motDePasseCtrl.dispose();
    super.dispose();
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
          child: ListenableBuilder(
            listenable: _controller,
            builder: (BuildContext context, Widget? child) {
              return Column(
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
                        : () => _controller.seConnecter(
                            _emailCtrl.text.trim(),
                            _motDePasseCtrl.text.trim(),
                          ),
                    child: _controller.envoiEnCours
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
                      MaterialPageRoute(
                        builder: (_) => const InscriptionPage(),
                      ),
                    ),
                    child: const Text(
                      'Créer un compte',
                      style: TextStyle(color: KColors.indigo),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
