import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teler_pro/controlers/command_ctr/commande_ctr.dart';
import 'package:teler_pro/controlers/nv_commande/nv_cmd_ctr.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/provider/test_ctr.dart';

/// [clientIdPreselectionne] : passé quand on arrive depuis la fiche client,
/// pour pré-remplir le sélecteur de client.
class NouvelleCommandePage extends ConsumerStatefulWidget {
  final String? clientIdPreselectionne;
  const NouvelleCommandePage({super.key, this.clientIdPreselectionne});

  @override
  ConsumerState<NouvelleCommandePage> createState() =>
      _NouvelleCommandePageState();
}

class _NouvelleCommandePageState extends ConsumerState<NouvelleCommandePage> {
  ClientModel? _clientSelectionne;
  String? _typeVetement;
  DateTime? _dateLivraison;
  final _prixCtrl = TextEditingController();
  final _acompteCtrl = TextEditingController();

  // 👈 Gestion des photos
  final List<File> _photos = [];
  final ImagePicker _picker = ImagePicker();

  bool _envoiEnCours = false;
  String? _erreur;

  final _typesVetement = const [
    'Robe pagne',
    'Costume',
    'Ensemble boubou',
    'Chemise',
    'Autre',
  ];
  final _tissus = const [
    ('Wax bleu', Color(0xFF2B4C8C)),
    ('Laiton doré', Color(0xFFC99A3C)),
    ('Terracotta', Color(0xFFB8562F)),
    ('Vert olive', Color(0xFF4C6B4F)),
  ];
  (String, Color)? _tissuSelectionne;

  @override
  void initState() {
    super.initState();
    if (widget.clientIdPreselectionne != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chargerClientPreselectionne(widget.clientIdPreselectionne!);
      });
    }
  }

  void _chargerClientPreselectionne(String clientId) async {
    final clientState = ref.read(nouvelleCommandeControllerProvider);
    final list = clientState.value ?? [];
    final match = list.where((c) => c.id == clientId).firstOrNull;
    if (match != null && mounted) {
      setState(() => _clientSelectionne = match);
    }
  }

  @override
  void dispose() {
    _prixCtrl.dispose();
    _acompteCtrl.dispose();
    super.dispose();
  }

  /// Sélection d'une ou plusieurs photos depuis la Galerie
  Future<void> _choisirPhotosGalerie(ImageSource gallery) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80, // Compression légère
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _photos.addAll(pickedFiles.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      print('Erreur lors de la sélection des photos : $e');
    }
  }

  /// Prise de photo unique depuis l'Appareil Photo
  Future<void> _prendrePhotoCamera(ImageSource camera) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _photos.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      print('Erreur lors de la prise de photo : $e');
    }
  }

  /// Dialogue pour choisir entre Appareil photo et Galerie
  void _afficherOptionPhoto() {
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
                _prendrePhotoCamera(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: KColors.indigo),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _choisirPhotosGalerie(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _creerCommande() async {
    if (_clientSelectionne == null ||
        _typeVetement == null ||
        _dateLivraison == null) {
      setState(() => _erreur = 'Merci de remplir les champs obligatoires');
      return;
    }

    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });

    try {
      final prixTotal =
          double.tryParse(_prixCtrl.text.replaceAll(' ', '')) ?? 0;
      final acompte =
          double.tryParse(_acompteCtrl.text.replaceAll(' ', '')) ?? 0;

      await ref
          .read(nouvelleCommandeControllerProvider.notifier)
          .creerCommande(
        clientId: _clientSelectionne!.id,
        clientNom: _clientSelectionne!.nom,
        typeVetement: _typeVetement!,
        dateLivraison: _dateLivraison!,
        prixTotal: prixTotal,
        acompte: acompte,
        tissu: _tissuSelectionne?.$1,
        photos: _photos, // 👈 Passage de la liste des fichiers photos
      );

      ref.invalidate(commandesControllerProvider);
      ref.invalidate(accueilControllerProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _erreur = 'Une erreur est survenue : $e');
      print('Erreur lors de la création de la commande : $e');
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      initialDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date != null) setState(() => _dateLivraison = date);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          top: true,
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                sliver: SliverList.list(
                  children: [
                    _fieldBlock('CLIENT', _buildClientField()),
                    _fieldBlock('TYPE DE VÊTEMENT', _buildTypeVetementField()),
                    _fieldBlock('PHOTOS / MODÈLES', _buildPhotosField()), // 👈 Bloc Photos
                    _fieldBlock('TISSU', _buildTissuField()),
                    _fieldBlock('LIVRAISON PRÉVUE', _buildDateField()),
                    Row(
                      children: [
                        Expanded(
                          child: _fieldBlock(
                            'PRIX TOTAL (FCFA)',
                            _buildTextField(_prixCtrl),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _fieldBlock(
                            'ACOMPTE (FCFA)',
                            _buildTextField(_acompteCtrl),
                          ),
                        ),
                      ],
                    ),
                    if (_erreur != null) ...[
                      Text(
                        _erreur!,
                        style: const TextStyle(
                          color: KColors.terracotta,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    ElevatedButton(
                      onPressed: _envoiEnCours ? null : _creerCommande,
                      child: _envoiEnCours
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Créer la commande'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: KColors.indigo,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: KColors.brassLight),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nouvelle commande',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldBlock(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              color: KColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  InputDecoration get _decoration => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: KColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: KColors.cardBorder),
    ),
  );

  Widget _buildClientField() {
    return InkWell(
      onTap: () async {
        final atelier = await atelierService.atelierCourant();
        final atelierId = atelier['id'] as String;
        final records = await pb
            .collection('clients')
            .getFullList(filter: 'atelier = "$atelierId"', sort: 'nom');
        final clients = records.map((r) => ClientModel.fromRecord(r)).toList();
        if (!mounted) return;

        if (clients.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aucun client — ajoutes-en un depuis l\'onglet Clients',
              ),
            ),
          );
          return;
        }

        final choix = await showModalBottomSheet<ClientModel>(
          context: context,
          builder: (_) => ListView(
            children: clients
                .map(
                  (c) => Padding(
                padding: const EdgeInsets.all(14.0),
                child: ListTile(
                  splashColor: KColors.indigo.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: KColors.cardBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(c.nom),
                  onTap: () => Navigator.pop(context, c),
                ),
              ),
            )
                .toList(),
          ),
        );
        if (choix != null) setState(() => _clientSelectionne = choix);
      },
      child: InputDecorator(
        decoration: _decoration,
        child: Text(
          _clientSelectionne?.nom ?? 'Sélectionner un client',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildTypeVetementField() {
    return DropdownButtonFormField<String>(
      initialValue: _typeVetement,
      decoration: _decoration,
      items: _typesVetement
          .map(
            (t) => DropdownMenuItem(
          value: t,
          child: Text(t, style: const TextStyle(fontSize: 13)),
        ),
      )
          .toList(),
      onChanged: (v) => setState(() => _typeVetement = v),
    );
  }

  /// Composant d'affichage des photos sélectionnées avec bouton d'ajout
  Widget _buildPhotosField() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _photos.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Bouton Ajouter Photo
            return GestureDetector(
              onTap: _afficherOptionPhoto,
              child: Container(
                width: 70,
                height: 70,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KColors.cardBorder),
                ),
                child: const Icon(
                  Icons.add_a_photo,
                  color: KColors.indigo,
                  size: 24,
                ),
              ),
            );
          }

          final file = _photos[index - 1];
          return Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KColors.cardBorder),
                  image: DecorationImage(
                    image: FileImage(file),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _photos.removeAt(index - 1);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTissuField() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _tissus.map((t) {
          final (nom, couleur) = t;
          final selectionne = _tissuSelectionne?.$1 == nom;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _tissuSelectionne = t),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: couleur,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selectionne ? KColors.indigo : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _choisirDate,
      child: InputDecorator(
        decoration: _decoration,
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 14,
              color: KColors.terracotta,
            ),
            const SizedBox(width: 8),
            Text(
              _dateLivraison != null
                  ? '${_dateLivraison!.day}/${_dateLivraison!.month}/${_dateLivraison!.year}'
                  : 'Choisir une date',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: _decoration,
      style: const TextStyle(fontSize: 13),
    );
  }
}