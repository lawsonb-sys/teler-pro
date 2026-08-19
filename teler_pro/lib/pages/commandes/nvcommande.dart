import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teler_pro/models/mockdata.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/bottomnav.dart';
import 'package:teler_pro/outils/themes.dart';

class NouvelleCommandePage extends StatefulWidget {
  final String? clientIdPreselectionne;
  const NouvelleCommandePage({super.key, this.clientIdPreselectionne});

  @override
  State<NouvelleCommandePage> createState() => _NouvelleCommandePageState();
}

class _NouvelleCommandePageState extends State<NouvelleCommandePage> {
  ClientModel? _clientSelectionne;
  String? _typeVetement;
  DateTime? _dateLivraison;
  final _prixCtrl = TextEditingController();
  final _acompteCtrl = TextEditingController();

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
      _clientSelectionne = MockData.clients.firstWhere(
        (c) => c.id == widget.clientIdPreselectionne,
        orElse: () => MockData.clients.first,
      );
    }
  }

  void _creerCommande() {
    if (_clientSelectionne == null ||
        _typeVetement == null ||
        _dateLivraison == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci de remplir les champs obligatoires'),
        ),
      );
      return;
    }
    // Pas de backend pour l'instant : on simule juste la création.
    Navigator.pop(context, true);
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

  InputDecoration get _decoration => InputDecoration(
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
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: const BoxDecoration(
                    color: KColors.indigo,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
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
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                sliver: SliverList.list(
                  children: [
                    _fieldBlock('CLIENT', _buildClientField()),
                    _fieldBlock('TYPE DE VÊTEMENT', _buildTypeVetementField()),
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
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _creerCommande,
                      child: const Text('Créer la commande'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: KuturaBottomNav(
            currentIndex: 2, // "Commandes"
            onTap: (i) {
              if (i == 0) Navigator.pushReplacementNamed(context, '/accueil');
            },
          ),
        ),
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

  Widget _buildClientField() {
    return InkWell(
      onTap: () async {
        final choix = await showModalBottomSheet<ClientModel>(
          context: context,
          builder: (_) => ListView(
            children: MockData.clients
                .map(
                  (c) => ListTile(
                    title: Text(c.nom),
                    onTap: () => Navigator.pop(context, c),
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
