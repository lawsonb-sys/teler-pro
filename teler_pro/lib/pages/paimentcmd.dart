import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:teler_pro/models/mockdata.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/bottomnav.dart';
import 'package:teler_pro/outils/themes.dart';

class PaiementCommandePage extends StatefulWidget {
  final String commandeId;
  const PaiementCommandePage({super.key, required this.commandeId});

  @override
  State<PaiementCommandePage> createState() => _PaiementCommandePageState();
}

class _PaiementCommandePageState extends State<PaiementCommandePage> {
  final _montantCtrl = TextEditingController();
  String _modeSelectionne = 'tmoney';

  late CommandeModel _commande;
  late List<PaiementModel> _paiements;

  @override
  void initState() {
    super.initState();
    _commande = MockData.commandes.firstWhere(
      (c) => c.id == widget.commandeId,
      orElse: () => MockData.commandes.first,
    );
    _paiements = widget.commandeId == 'o1'
        ? List.from(MockData.paiementsCommande1)
        : [];
  }

  void _enregistrerPaiement() {
    final montant = double.tryParse(_montantCtrl.text.replaceAll(' ', ''));
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saisir un montant valide')));
      return;
    }
    setState(() {
      _paiements.insert(
        0,
        PaiementModel(
          id: 'tmp-${_paiements.length}',
          montant: montant,
          mode: _modeSelectionne,
          createdAt: DateTime.now(),
        ),
      );
      final nouveauPaye = _commande.montantPaye + montant;
      _commande = CommandeModel(
        id: _commande.id,
        clientId: _commande.clientId,
        clientNom: _commande.clientNom,
        typeVetement: _commande.typeVetement,
        tissu: _commande.tissu,
        prixTotal: _commande.prixTotal,
        statut: _commande.statut,
        dateLivraisonPrevue: _commande.dateLivraisonPrevue,
        montantPaye: nouveauPaye,
      );
      _montantCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    //   final fmt = NumberFormat.decimalPattern('fr');
    final c = _commande;

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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                      const SizedBox(height: 6),
                      Text(
                        '${c.clientNom} · ${c.typeVetement}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB7C2D2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Column(
                          children: [
                            //Text('${fmt.format(c.prixTotal)} FCFA',
                            //    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: Colors.white)),
                            Text(
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
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: c.progression,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFEDE6D5),
                          valueColor: const AlwaysStoppedAnimation(
                            KColors.threadGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //Text('Payé ${fmt.format(c.montantPaye)}', style: const TextStyle(fontSize: 10, color: KColors.muted)),
                          //Text('Reste dû ${fmt.format(c.soldeDu)}', style: const TextStyle(fontSize: 10, color: KColors.muted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
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
              SliverList.builder(
                itemCount: _paiements.length,
                itemBuilder: (context, i) {
                  final p = _paiements[i];
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
                            //  Text(DateFormat('d MMM yyyy', 'fr').format(p.createdAt), style: const TextStyle(fontSize: 10, color: KColors.muted)),
                          ],
                        ),
                        //Text('+${fmt.format(p.montant)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: KColors.threadGreen)),
                      ],
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(child: _buildAjoutPaiement()),
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

  Widget _buildAjoutPaiement() {
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
          Text(
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
              onPressed: _enregistrerPaiement,
              child: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}
