import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/models/pocketbase.dart';
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
  bool _envoiEnCours = false;

  late Future<_PaiementData> _future;

  @override
  void initState() {
    super.initState();
    _future = _charger();
  }

  Future<_PaiementData> _charger() async {
    final commandeRecord = await pb
        .collection('commandes')
        .getOne(widget.commandeId, expand: 'client');

    final paiementsRecords = await pb
        .collection('paiements')
        .getFullList(
          filter: 'commande = "${widget.commandeId}"',
          sort: '-created',
        );
    final paiements = paiementsRecords
        .map((r) => PaiementModel.fromRecord(r))
        .toList();

    final montantPaye = paiements.fold<double>(0, (s, p) => s + p.montant);
    final commande = CommandeModel.fromRecord(
      commandeRecord,
      montantPaye: montantPaye,
    );

    return _PaiementData(commande: commande, paiements: paiements);
  }

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
      await pb
          .collection('paiements')
          .create(
            body: {
              'commande': widget.commandeId,
              'montant': montant,
              'mode': _modeSelectionne,
            },
          );
      _montantCtrl.clear();
      setState(() => _future = _charger());
      await _future;
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

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('fr');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          top: true,
          bottom: false,
          child: FutureBuilder<_PaiementData>(
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
              final c = data.commande;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHero(context, c, fmt)),
                  SliverToBoxAdapter(child: _buildSplitBar(c, fmt)),
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
                  if (data.paiements.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Aucun paiement enregistré',
                        style: TextStyle(color: KColors.muted, fontSize: 12),
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
                                '+${fmt.format(p.montant)}',
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

  Widget _buildHero(BuildContext context, CommandeModel c, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
          const SizedBox(height: 6),
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
                'Payé ${fmt.format(c.montantPaye)}',
                style: const TextStyle(fontSize: 10, color: KColors.muted),
              ),
              Text(
                'Reste dû ${fmt.format(c.soldeDu)}',
                style: const TextStyle(fontSize: 10, color: KColors.muted),
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

class _PaiementData {
  final CommandeModel commande;
  final List<PaiementModel> paiements;
  _PaiementData({required this.commande, required this.paiements});
}
