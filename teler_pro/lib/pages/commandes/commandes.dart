import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teler_pro/models/mockdata.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/pages/paimentcmd.dart';

class CommandesPage extends StatefulWidget {
  const CommandesPage({super.key});

  @override
  State<CommandesPage> createState() => _CommandesPageState();
}

class _CommandesPageState extends State<CommandesPage> {
  String _filtre = 'toutes';

  final _filtres = const [
    ('toutes', 'Toutes'),
    ('attente', 'En attente'),
    ('en_cours', 'En cours'),
    ('pret', 'Prêtes'),
    ('livre', 'Livrées'),
  ];

  @override
  Widget build(BuildContext context) {
    final commandes = _filtre == 'toutes'
        ? MockData.commandes
        : MockData.commandes.where((c) => c.statut == _filtre).toList();

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
                    onSelected: (_) => setState(() => _filtre = value),
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
            child: commandes.isEmpty
                ? Center(
                    child: Text(
                      'Aucune commande',
                      style: TextStyle(color: KColors.muted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: commandes.length,
                    itemBuilder: (context, i) =>
                        _CommandeCard(commande: commandes[i]),
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
