import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/authservcice.dart';
import 'package:teler_pro/outils/exp.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controlers/users/user_ctr.dart';

class ProfilPage extends ConsumerStatefulWidget {
  const ProfilPage({super.key});

  @override
  ConsumerState<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends ConsumerState<ProfilPage> {
  bool _modeEdition = false;
  bool _envoiEnCours = false;
  bool _photoSupprimee = false; // 👈 Pour gérer la suppression explicite
  File? _imageSelectionnee;

  final _nomCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _nomUserCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telephoneCtrl.dispose();
    _villeCtrl.dispose();
    _nomUserCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  /// Boîte de dialogue pour choisir entre Galerie et Appareil photo
  void _afficherDialogueSourceImage({required bool aDejaUneImage}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Photo de profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library, color: KColors.indigo),
                title: const Text('Choisir dans la galerie'),
                onTap: () {
                  Navigator.pop(ctx);
                  _choisirImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: KColors.indigo),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _choisirImage(ImageSource.camera);
                },
              ),
              if ((aDejaUneImage && !_photoSupprimee) || _imageSelectionnee != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: KColors.terracotta),
                  title: const Text(
                    'Supprimer la photo',
                    style: TextStyle(color: KColors.terracotta),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _imageSelectionnee = null;
                      _photoSupprimee = true; // Indique qu'on veut supprimer l'avatar
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sélection et compression de l'image
  Future<void> _choisirImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxHeight: 500,
      maxWidth: 500,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() {
        _imageSelectionnee = File(pickedFile.path);
        _photoSupprimee = false;
      });
    }
  }

  /// Remplit les champs textes à partir des données réelles
  void _initialiserChamps(
      Map<String, dynamic> atelier,
      Map<String, dynamic> user,
      ) {
    _nomCtrl.text = atelier['nom'] as String? ?? '';
    _telephoneCtrl.text = atelier['telephone'] as String? ?? '';
    _villeCtrl.text = atelier['ville'] as String? ?? '';
    _emailCtrl.text = user['email'] as String? ?? '';
    _nomUserCtrl.text = user['name'] as String? ?? '';
    _imageSelectionnee = null;
    _photoSupprimee = false;
  }

  Future<void> _enregistrer(String atelierId, String userId) async {
    setState(() => _envoiEnCours = true);
    try {
      final bodyAtelier = {
        'nom': _nomCtrl.text.trim(),
        'telephone': _telephoneCtrl.text.trim(),
        'ville': _villeCtrl.text.trim(),
      };

      final bodyUser = <String, dynamic>{
        'name': _nomUserCtrl.text.trim(),
      };

      // Si l'utilisateur a choisi de supprimer la photo
      if (_photoSupprimee) {
        bodyUser['avatar'] = null; // Réinitialise l'avatar dans PocketBase
      }

      // 💡 Transmet `_imageSelectionnee` SANS le point d'exclamation !
      await ref
          .read(atelierUserProvider.notifier)
          .modifier(
        atelierId,
        userId,
        bodyAtelier,
        bodyUser,
        _imageSelectionnee, // Accepte null si aucune nouvelle photo n'a été choisie
      );

      if (mounted) {
        setState(() {
          _modeEdition = false;
          _photoSupprimee = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Profil mis à jour avec succès'),
          ),
        );
      }
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
    ref.listen<AsyncValue<AtelierUserData>>(atelierUserProvider, (
        previous,
        next,
        ) {
      next.whenData((data) {
        final nomAtelier = data.atelier['nom'] as String? ?? 'Mon Atelier';
        ref.read(nomAtelierProvider.notifier).state = nomAtelier;
      });
    });

    final atelierUserAsync = ref.watch(atelierUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (!_modeEdition)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                atelierUserAsync.whenData((data) {
                  _initialiserChamps(data.atelier, data.user);
                  setState(() => _modeEdition = true);
                });
              },
            ),
        ],
      ),
      body: atelierUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Erreur : $err',
            style: const TextStyle(color: KColors.terracotta),
          ),
        ),
        data: (data) {
          final atelier = data.atelier;
          final user = data.user;
          final nomAtelier = atelier['nom'] as String? ?? 'Mon Atelier';
          final email = user['email'] as String? ?? '';
          final nom = user['name'] as String? ?? '';
          final avatarFileName = user['avatar'] as String? ?? '';
          final statutAbonnement =
              atelier['statut_abonnement'] as String? ?? 'essai';
          final telephone = atelier['telephone'] as String?;
          final ville = atelier['ville'] as String?;
          final atelierId = atelier['id'] as String;
          final userId = user['id'] as String;

          final String? avatarUrl = (avatarFileName.isNotEmpty && !_photoSupprimee)
              ? '${pb.baseURL}/api/files/users/$userId/$avatarFileName'
              : null;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        // 🟢 AFFICHAGE DE L'AVATAR
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: _imageSelectionnee != null
                              ? CircleAvatar(
                            radius: 50,
                            backgroundImage: FileImage(
                              _imageSelectionnee!,
                            ),
                          )
                              : (avatarUrl != null
                              ? CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: avatarUrl,
                            imageBuilder:
                                (context, imageProvider) =>
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage:
                                  imageProvider,
                                ),
                            placeholder: (context, url) =>
                            const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: KColors.indigo,
                                  child: Text(
                                    nom.isNotEmpty
                                        ? nom[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                    ),
                                  ),
                                ),
                          )
                              : CircleAvatar(
                            radius: 50,
                            backgroundColor: KColors.indigo,
                            child: Text(
                              nom.isNotEmpty
                                  ? nom[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                        ),
                        if (_modeEdition)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _afficherDialogueSourceImage(
                                aDejaUneImage: avatarUrl != null,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: KColors.indigo,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_modeEdition) ...[
                      Text(
                        nom,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: KColors.muted,
                        ),
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
                  controller: _nomUserCtrl,
                  decoration: _decoration('Nom de l\'utilisateur'),
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
                            : () => setState(() {
                          _modeEdition = false;
                          _photoSupprimee = false;
                        }),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _envoiEnCours
                            ? null
                            : () => _enregistrer(atelierId, userId),
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
                  label: 'Atelier',
                  valeur: nomAtelier.isNotEmpty ? nomAtelier : 'Non renseigné',
                ),
                _InfoRow(
                  label: 'Abonnement',
                  valeur: _labelStatut(statutAbonnement),
                ),
                _InfoRow(
                  label: 'Téléphone',
                  valeur: telephone?.isNotEmpty == true
                      ? telephone!
                      : 'Non renseigné',
                ),
                _InfoRow(
                  label: 'Ville',
                  valeur: ville?.isNotEmpty == true ? ville! : 'Non renseignée',
                ),
                if (statutAbonnement != 'actif') ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _ouvrirPagePaiement(atelierId),
                    child: const Text('S\'abonner'),
                  ),
                ],
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () async {
                    await authService.deconnecter();
                    await ref
                        .read(atelierUserProvider.notifier)
                        .reinitialiserCache();
                  },
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
    final url = Uri.parse('${pb.baseURL}/checkout.html?atelier=$atelierId');
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
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: KColors.muted),
            ),
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