import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:teler_pro/controlers/command_ctr/commande_ctr.dart';
import 'package:teler_pro/controlers/paiment_ctr/paiement_controller.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/models/pocketbase.dart'; // Import pour 'pb' ou l'URL PocketBase
import 'package:teler_pro/outils/themes.dart';

class PaiementCommandePage extends ConsumerStatefulWidget {
  final String commandeId;
  const PaiementCommandePage({super.key, required this.commandeId});

  @override
  ConsumerState<PaiementCommandePage> createState() =>
      _PaiementCommandePageState();
}

class _PaiementCommandePageState extends ConsumerState<PaiementCommandePage> {
  final _montantCtrl = TextEditingController();
  String _modeSelectionne = 'tmoney';
  bool _envoiEnCours = false;
  bool _ajoutPhotoEnCours = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _montantCtrl.dispose();
    super.dispose();
  }

  // --- Gestion des photos ---

  Future<void> _choisirPhotosGalerie() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );
      if (pickedFiles.isNotEmpty) {
        await _ajouterPhotosALaCommande(
          pickedFiles.map((x) => File(x.path)).toList(),
        );
      }
    } catch (e) {
      _afficherErreur('Erreur lors de la sélection des photos : $e');
    }
  }

  Future<void> _prendrePhotoCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        await _ajouterPhotosALaCommande([File(pickedFile.path)]);
      }
    } catch (e) {
      _afficherErreur('Erreur lors de la prise de photo : $e');
    }
  }

  void _afficherModalChoixPhoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: KColors.indigo),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(ctx);
                _prendrePhotoCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: KColors.indigo),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _choisirPhotosGalerie();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ajouterPhotosALaCommande(List<File> nouvellesPhotos) async {
    if (nouvellesPhotos.isEmpty) return;

    setState(() => _ajoutPhotoEnCours = true);

    try {
      await ref
          .read(paiementControllerProvider(widget.commandeId).notifier)
          .ajouterPhotos(nouvellesPhotos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo(s) ajoutée(s) avec succès')),
        );
      }
    } catch (e) {
      _afficherErreur('Erreur lors de l\'ajout des photos : $e');
    } finally {
      if (mounted) setState(() => _ajoutPhotoEnCours = false);
    }
  }

  void _afficherErreur(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: KColors.terracotta),
    );
  }

  void _ouvrirPleinEcranImage(ImageProvider imageProvider) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image(image: imageProvider, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Gestion du statut ---

  Future<void> _changerStatutCommande(CommandeModel commande) async {
    final statuts = [
      {'code': 'attente', 'label': 'En attente'},
      {'code': 'en_cours', 'label': 'En cours'},
      {'code': 'pret', 'label': 'Prêt à livrer'},
      {'code': 'livre', 'label': 'Livré'},
    ];

    final nouveauStatut = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Changer le statut',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: KColors.indigo,
                ),
              ),
            ),
            const Divider(),
            ...statuts.map(
                  (s) => ListTile(
                title: Text(s['label']!),
                trailing: commande.statut.toLowerCase() == s['code']
                    ? const Icon(Icons.check_circle, color: KColors.indigo)
                    : null,
                onTap: () => Navigator.pop(ctx, s['code']),
              ),
            ),
          ],
        ),
      ),
    );

    if (nouveauStatut != null && nouveauStatut != commande.statut) {
      try {
        await ref
            .read(paiementControllerProvider(widget.commandeId).notifier)
            .changerStatut(nouveauStatut);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Statut mis à jour : $nouveauStatut')),
          );
        }
      } catch (e) {
        _afficherErreur('Erreur : $e');
      }
    }
  }

  // --- Enregistrement du paiement ---

  Future<void> _enregistrerPaiement() async {
    final montant = double.tryParse(_montantCtrl.text.replaceAll(' ', ''));
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saisir un montant valide')));
      return;
    }

    setState(() => _envoiEnCours = true);

    try {
      await ref
          .read(paiementControllerProvider(widget.commandeId).notifier)
          .enregistrerPaiement(montant: montant, mode: _modeSelectionne);

      _montantCtrl.clear();
      FocusScope.of(context).unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement enregistré avec succès')),
        );
      }
    } catch (e) {
      _afficherErreur('Erreur : $e');
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(paiementControllerProvider(widget.commandeId));
    final fmt = NumberFormat.decimalPattern('fr');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text(
                'Erreur : $err',
                style: const TextStyle(color: KColors.terracotta),
              ),
            ),
            data: (data) {
              final c = data.commande;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHero(context, c, fmt)),
                  SliverToBoxAdapter(child: _buildSplitBar(c, fmt)),

                  // 👈 Bloc Photos / Modèles
                  SliverToBoxAdapter(child: _buildSectionPhotos(c)),

                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(18, 16, 18, 4),
                      child: Text(
                        'HISTORIQUE DES PAIEMENTS',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: KColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (data.paiements.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        child: Text(
                          'Aucun paiement enregistré',
                          style: TextStyle(color: KColors.muted, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: data.paiements.length,
                      itemBuilder: (context, i) {
                        final p = data.paiements[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.modeLabel,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'd MMM yyyy',
                                      'fr',
                                    ).format(p.createdAt),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: KColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '+${fmt.format(p.montant)} FCFA',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: KColors.threadGreen,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  SliverToBoxAdapter(child: _buildAjoutPaiement(context)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Composant d'affichage des photos ---

  Widget _buildSectionPhotos(CommandeModel c) {
    // Si votre modèle possède un champ pour les photos locales (hors-ligne) et enregistrées
    final List<String> photosPocketBase = c.photos;
    // Adaptez si vous avez un champ dédié aux fichiers locaux dans CommandeModel (ex: c.photosLocales)
    final List<File> photosLocales = c.photosLocales ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PHOTOS / MODÈLES',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: KColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_ajoutPhotoEnCours)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 75,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Bouton Ajouter une photo
                GestureDetector(
                  onTap: _ajoutPhotoEnCours ? null : _afficherModalChoixPhoto,
                  child: Container(
                    width: 75,
                    height: 75,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KColors.cardBorder),
                    ),
                    child: const Icon(
                      Icons.add_a_photo,
                      color: KColors.indigo,
                      size: 22,
                    ),
                  ),
                ),

                // Photos chargées depuis PocketBase
                ...photosPocketBase.map((nomFichier) {
                  final imageUrl =
                      '${pb.baseUrl}/api/files/commandes/${c.id}/$nomFichier';
                  final imageProvider = NetworkImage(imageUrl);

                  return GestureDetector(
                    onTap: () => _ouvrirPleinEcranImage(imageProvider),
                    child: Container(
                      width: 75,
                      height: 75,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KColors.cardBorder),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }),

                // Photos locales en attente de synchronisation
                ...photosLocales.map((file) {
                  final imageProvider = FileImage(file);

                  return GestureDetector(
                    onTap: () => _ouvrirPleinEcranImage(imageProvider),
                    child: Container(
                      width: 75,
                      height: 75,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KColors.indigo, width: 1.5),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }),

                if (photosPocketBase.isEmpty && photosLocales.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                        'Aucune photo',
                        style: TextStyle(color: KColors.muted, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, CommandeModel c, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: KColors.indigo,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.arrow_back, color: KColors.brassLight),
              ),
              InkWell(
                onTap: () => _changerStatutCommande(c),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      StatutBadge(statut: c.statut),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit,
                        size: 14,
                        color: KColors.brassLight,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${c.clientNom} · ${c.typeVetement}',
            style: const TextStyle(fontSize: 11, color: Color(0xFFB7C2D2)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Column(
              children: [
                Text(
                  '${fmt.format(c.prixTotal)} FCFA',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'PRIX TOTAL DE LA COMMANDE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: KColors.brassLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitBar(CommandeModel c, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: c.progression,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDE6D5),
              valueColor: const AlwaysStoppedAnimation(KColors.threadGreen),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payé ${fmt.format(c.montantPaye)} FCFA',
                style: const TextStyle(fontSize: 10, color: KColors.muted),
              ),
              Text(
                'Reste dû ${fmt.format(c.soldeDu)} FCFA',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: KColors.terracotta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAjoutPaiement(BuildContext context) {
    final modes = const [
      ('tmoney', 'T-Money'),
      ('flooz', 'Flooz'),
      ('especes', 'Espèces'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENREGISTRER UN PAIEMENT',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              color: KColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _montantCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Montant reçu — FCFA',
              filled: true,
              fillColor: KColors.ecru,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: modes.map((m) {
              final (value, label) = m;
              final selectionne = _modeSelectionne == value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _modeSelectionne = value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selectionne
                            ? const Color(0xFFEEF1F6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectionne
                              ? KColors.indigo
                              : KColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: selectionne ? KColors.indigo : KColors.muted,
                          fontWeight: selectionne
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _envoiEnCours ? null : _enregistrerPaiement,
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
    );
  }
}