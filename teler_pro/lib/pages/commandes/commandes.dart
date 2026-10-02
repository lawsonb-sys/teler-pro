import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teler_pro/controlers/command_ctr/commande_ctr.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/pages/commandes/nvcommande.dart';
import 'package:teler_pro/pages/paimentcmd.dart';
import 'package:teler_pro/provider/test_ctr.dart';

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
  Widget build(BuildContext context) {
    final statecmd = ref.watch(commandesControllerProvider);
    final controller = ref.read(commandesControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: statecmd.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Erreur: $err',
                  style: const TextStyle(color: KColors.terracotta),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => controller.rafraichir(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
          data: (commandes) {
            return RefreshIndicator(
              onRefresh: () async => controller.rafraichir(),
              child: CustomScrollView(
                slivers: [
                  // 1. En-tête Hero identique à la page d'accueil
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      totalCommandes: commandes.length,
                      filtreActuel: controller.filtreActuel,
                      onFiltreChanged: (val) => controller.changerFiltre(val),
                    ),
                  ),

                  // 2. Espace / Marge sous le header
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // 3. Message si liste vide
                  if (commandes.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Text(
                            'Aucune commande enregistrée.',
                            style: TextStyle(
                              color: KColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    // 4. Liste des cartes de commandes
                    SliverList.builder(
                      itemCount: commandes.length,
                      itemBuilder: (context, i) =>
                          _CommandeCard(commande: commandes[i]),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_commandes_page',
        onPressed: () async {
          final cree = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const NouvelleCommandePage()),
          );

          if (cree == true && context.mounted) {
            ref.invalidate(commandesControllerProvider);
            ref.invalidate(accueilControllerProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// En-tête bleu indigo inspiré de la page Accueil
  Widget _buildHeader({
    required int totalCommandes,
    required String filtreActuel,
    required ValueChanged<String> onFiltreChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: KColors.indigo,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GESTION',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: KColors.brassLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Commandes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              // Badge réactif du nombre de commandes affichées
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$totalCommandes commande${totalCommandes > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KColors.brassLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barre horizontale de filtres sous forme de Chips dans le Header
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filtres.map((f) {
                final estSelectionne = filtreActuel == f.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.$2),
                    selected: estSelectionne,
                    onSelected: (_) {
                      ref
                          .read(commandesControllerProvider.notifier)
                          .changerFiltre(f.$1);
                    },
                    selectedColor: KColors.brassLight,
                    backgroundColor: Colors.white.withValues(alpha: 0.5),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: KColors.indigo,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: estSelectionne
                            ? KColors.brassLight
                            : Colors.transparent,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
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
                              commande.clientNom.isNotEmpty
                                  ? commande.clientNom
                                  : '—',
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
