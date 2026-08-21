import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/pages/paimentcmd.dart';

class CommandesPage extends StatefulWidget {
  const CommandesPage({super.key});

  @override
  State<CommandesPage> createState() => _CommandesPageState();
}

class _CommandesPageState extends State<CommandesPage> {
  String _filtre = 'toutes';
  late Future<List<CommandeModel>> _future;

  final _filtres = const [
    ('toutes', 'Toutes'),
    ('attente', 'En attente'),
    ('en_cours', 'En cours'),
    ('pret', 'Prêtes'),
    ('livre', 'Livrées'),
  ];

  @override
  void initState() {
    super.initState();
    _future = _charger();
  }

  Future<List<CommandeModel>> _charger() async {
    final atelier = await atelierService.atelierCourant();

    // Filtre construit dynamiquement : toujours restreint à l'atelier courant,
    // et en plus au statut sélectionné si ce n'est pas "toutes".
    var filtre = 'atelier = "${atelier.id}"';
    if (_filtre != 'toutes') {
      filtre += ' && statut = "$_filtre"';
    }

    final records = await pb
        .collection('commandes')
        .getFullList(
          filter: filtre,
          sort: 'date_livraison_prevue',
          expand: 'client',
        );

    final commandes = <CommandeModel>[];
    for (final r in records) {
      final paiements = await pb
          .collection('paiements')
          .getFullList(filter: 'commande = "${r.id}"');
      final montantPaye = paiements.fold<double>(
        0,
        (s, p) => s + (p.data['montant'] as num).toDouble(),
      );
      commandes.add(CommandeModel.fromRecord(r, montantPaye: montantPaye));
    }
    return commandes;
  }

  void _appliquerFiltre(String f) {
    setState(() {
      _filtre = f;
      _future = _charger();
    });
  }

  Future<void> _rafraichir() async {
    setState(() => _future = _charger());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commandes')),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _filtres.map((f) {
                final (value, label) = f;
                final actif = _filtre == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: actif,
                    onSelected: (_) => _appliquerFiltre(value),
                    selectedColor: KColors.indigo,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: actif ? Colors.white : KColors.muted,
                    ),
                    side: BorderSide(
                      color: actif ? KColors.indigo : KColors.cardBorder,
                    ),
                    backgroundColor: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CommandeModel>>(
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
                final commandes = snap.data!;
                // RefreshIndicator enveloppe TOUJOURS un widget défilable,
                // même l'état vide — sinon le tirer-actualiser ne répond pas
                // (le bug qu'on avait eu sur ClientsPage).
                return RefreshIndicator(
                  onRefresh: _rafraichir,
                  child: commandes.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Text(
                                  'Aucune commande',
                                  style: TextStyle(color: KColors.muted),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: commandes.length,
                          itemBuilder: (context, i) =>
                              _CommandeCard(commande: commandes[i]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandeCard extends StatelessWidget {
  final CommandeModel commande;
  const _CommandeCard({required this.commande});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('fr');
    final dateStr = commande.dateLivraisonPrevue != null
        ? DateFormat('d MMM', 'fr').format(commande.dateLivraisonPrevue!)
        : '—';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaiementCommandePage(commandeId: commande.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commande.clientNom,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${commande.typeVetement} — ${commande.tissu ?? ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: KColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatutBadge(statut: commande.statut),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: commande.progression,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFEDE6D5),
                  valueColor: const AlwaysStoppedAnimation(KColors.threadGreen),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    commande.soldeDu > 0
                        ? 'Solde dû · ${fmt.format(commande.soldeDu)} FCFA'
                        : 'Payée intégralement',
                    style: const TextStyle(fontSize: 10, color: KColors.muted),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 10, color: KColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
