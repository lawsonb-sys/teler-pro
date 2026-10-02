import 'package:flutter/material.dart';
import 'package:teler_pro/controlers/connexion_ctr.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/pages/connexion/inscription.dart';
import 'package:url_launcher/url_launcher.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  bool _estEnChargement = false;
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

  Future<void> _seConnecterAvecGoogle() async {
    setState(() => _estEnChargement = true);

    try {
      // 🚀 Lancement du flux OAuth2 nativement avec PocketBase
      final authData = await pb.collection('users').authWithOAuth2('google', (
        url,
      ) async {
        // Ouvre l'interface Google dans le navigateur du téléphone
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          throw Exception('Impossible d\'ouvrir l\'URL de connexion');
        }
      });

      if (pb.authStore.isValid && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bienvenue ${authData.record?.getStringValue('name') ?? '!'}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de la connexion Google : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _estEnChargement = false);
      }
    }
  }

  Future<void> connectWithGoogle() async {
    try {
      final authData = await pb.collection('users').authWithOAuth2('google', ((
        url,
      ) async {
        await launchUrl(url);
      }));
      print('Connecté avec succès : ${authData.record}');
    } catch (e) {
      print('Erreur de connexion Google : $e');
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 45),
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
                    Center(
                      child: Text(
                        'Ou Connecter avec :',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _estEnChargement
                            ? null
                            : _seConnecterAvecGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: _estEnChargement
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // ⚡ Logo local depuis les assets
                                  Image.asset(
                                    'assets/g.png',
                                    height: 30,
                                    width: 30,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Continuer avec Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
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
