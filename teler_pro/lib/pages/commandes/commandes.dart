import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 Import Riverpod
import 'package:intl/intl.dart';
import 'package:teler_pro/controlers/commande_ctr.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/providers.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/pages/paimentcmd.dart';

// 1. Conversion en ConsumerStatefulWidget
class CommandesPage extends ConsumerStatefulWidget {
  const CommandesPage({super.key});

  @override
  ConsumerState<CommandesPage> createState() => _CommandesPageState();
}

class _CommandesPageState extends ConsumerState<CommandesPage> {
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
    // 💡 Chargement initial via le provider Riverpod (micro-tâche pour éviter les conflits d'init)
    Future.microtask(() {
      ref.read(commandesControllerProvider).charger();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Écoute de tout changement dans le contrôleur via Riverpod
    final controller = ref.watch(commandesControllerProvider);

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
                final actif = controller.filtre == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: actif,
                    onSelected: (_) => controller.changerFiltre(value),
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
          Expanded(child: _buildCorps(controller)),
        ],
      ),
    );
  }

  Widget _buildCorps(CommandesController controller) {
    if (controller.erreur != null) {
      return Center(
        child: Text(
          controller.erreur!,
          style: const TextStyle(color: KColors.terracotta),
        ),
      );
    }
    if (controller.chargement && controller.commandes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final commandes = controller.commandes;

    return RefreshIndicator(
      onRefresh: controller.charger,
      child: commandes.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(
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

    final detailsText = [
      commande.typeVetement,
      if (commande.tissu != null && commande.tissu!.isNotEmpty) commande.tissu!,
    ].join(' — ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (commande.enAttente) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Cette commande sera synchronisée dès que la connexion revient',
                ),
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaiementCommandePage(commandeId: commande.id),
            ),
          );
        },
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
                        Row(
                          children: [
                            Text(
                              commande.clientNom,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (commande.enAttente) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.cloud_off,
                                size: 12,
                                color: Color(0xFF8A6A1F),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detailsText,
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
                  value: commande.progression.clamp(0.0, 1.0),
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
