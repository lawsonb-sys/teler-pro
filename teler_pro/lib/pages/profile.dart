import 'package:flutter/material.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';
import 'package:teler_pro/outils/authservcice.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  late Future<_ProfilData> _future;
  bool _modeEdition = false;
  bool _envoiEnCours = false;

  final _nomCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _charger();
  }

  Future<_ProfilData> _charger() async {
    final atelier = await atelierService.atelierCourant();
    _nomCtrl.text = atelier.getStringValue('nom');
    _telephoneCtrl.text = atelier.data['telephone'] as String? ?? '';
    _villeCtrl.text = atelier.data['ville'] as String? ?? '';

    return _ProfilData(
      nom: atelier.getStringValue('nom'),
      statutAbonnement: atelier.getStringValue('statut_abonnement'),
      telephone: atelier.data['telephone'] as String?,
      ville: atelier.data['ville'] as String?,
      email: pb.authStore.record?.getStringValue('email') ?? '',
      atelierId: atelier.id,
    );
  }

  Future<void> _enregistrer() async {
    setState(() => _envoiEnCours = true);
    try {
      final atelier = await atelierService.atelierCourant();
      await pb
          .collection('ateliers')
          .update(
            atelier.id,
            body: {
              'nom': _nomCtrl.text.trim(),
              'telephone': _telephoneCtrl.text.trim(),
              'ville': _villeCtrl.text.trim(),
            },
          );
      atelierService
          .reinitialiserCache(); // le cache doit être invalidé après modification
      setState(() {
        _modeEdition = false;
        _future = _charger();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (!_modeEdition)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _modeEdition = true),
            ),
        ],
      ),
      body: FutureBuilder<_ProfilData>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                'Erreur : ${snap.error}',
                style: const TextStyle(color: KColors.terracotta),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: const BoxDecoration(
                        color: KColors.indigo,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          data.nom.isNotEmpty ? data.nom[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!_modeEdition) ...[
                      Text(
                        data.nom,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.email,
                        style: TextStyle(fontSize: 12, color: KColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_modeEdition) ...[
                TextField(
                  controller: _nomCtrl,
                  decoration: _decoration('Nom de l\'atelier'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _telephoneCtrl,
                  decoration: _decoration('Téléphone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _villeCtrl,
                  decoration: _decoration('Ville'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _envoiEnCours
                            ? null
                            : () => setState(() => _modeEdition = false),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _envoiEnCours ? null : _enregistrer,
                        child: _envoiEnCours
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _InfoRow(
                  label: 'Abonnement',
                  valeur: _labelStatut(data.statutAbonnement),
                ),
                _InfoRow(
                  label: 'Téléphone',
                  valeur: data.telephone?.isNotEmpty == true
                      ? data.telephone!
                      : 'Non renseigné',
                ),
                _InfoRow(
                  label: 'Ville',
                  valeur: data.ville?.isNotEmpty == true
                      ? data.ville!
                      : 'Non renseignée',
                ),

                if (data.statutAbonnement != 'actif') ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      print('kolokol');
                      _ouvrirPagePaiement(data.atelierId);
                    },
                    child: const Text('S\'abonner'),
                  ),
                ],
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () => authService.deconnecter(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KColors.terracotta,
                    side: const BorderSide(color: KColors.terracotta),
                  ),
                  child: const Text('Se déconnecter'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _labelStatut(String statut) => switch (statut) {
    'essai' => 'Période d\'essai',
    'actif' => 'Actif',
    'expire' => 'Expiré',
    _ => statut,
  };

  Future<void> _ouvrirPagePaiement(String atelierId) async {
    // La page checkout.html est servie directement par ton PocketBase,
    // depuis pb_public/ — pas besoin d'un serveur web séparé.
    final url = Uri.parse('${pb.baseURL}/checkout.html?atelier=$atelierId');

    // externalApplication = force l'ouverture dans le navigateur du système,
    // jamais dans une WebView intégrée — important pour rester dans les
    // clous des règles Google Play sur les paiements in-app.
    final ouvert = await launchUrl(url, mode: LaunchMode.externalApplication);

    if (!ouvert && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir la page de paiement'),
        ),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String valeur;
  const _InfoRow({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: MediaQuery.of(context).size.height * 0.07,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: KColors.muted)),
            Text(
              valeur,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilData {
  final String atelierId;
  final String nom;
  final String statutAbonnement;
  final String? telephone;
  final String? ville;
  final String email;

  _ProfilData({
    required this.nom,
    required this.statutAbonnement,
    required this.telephone,
    required this.ville,
    required this.email,
    required this.atelierId,
  });
}
