import 'package:flutter/material.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/accueil_ctr.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/pages/commandes/nvcommande.dart';
import 'package:teler_pro/pages/paimentcmd.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  late final AccueilController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AccueilController();
    _controller.charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String getSalutation() {
    final hour = DateTime.now().hour;
    return (hour >= 5 && hour < 12) ? 'BONJOUR' : 'BONSOIR';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<AccueilState>(
        valueListenable: _controller,
        builder: (context, state, _) {
          return switch (state) {
            AccueilLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            AccueilError(:final message) => Center(
              child: Text(
                'Erreur : $message',
                style: const TextStyle(color: KColors.terracotta),
              ),
            ),
            AccueilSuccess(:final data) => RefreshIndicator(
              onRefresh: _controller.rafraichir,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(data.nomAtelier)),
                  SliverToBoxAdapter(child: _buildStats(data)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Commandes récentes :',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (data.commandes.isNotEmpty)
                            Text(
                              '${data.commandes.length} au total',
                              style: const TextStyle(
                                fontSize: 12,
                                color: KColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (data.commandes.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Aucune commande pour le moment',
                          style: TextStyle(color: KColors.muted),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final commande = data.commandes[index];

                        print(
                          'Commandes: ${commande.id}, Client: ${commande.clientNom}, Statut: ${commande.statut}',
                        );
                        return _CommandeTile(
                          commande: commande,
                          onrefresh: _controller.charger,
                        );
                      }, childCount: data.commandes.length),
                    ),
                ],
              ),
            ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'accueil_fab',
        onPressed: () async {
          final cree = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const NouvelleCommandePage()),
          );
          if (cree == true && mounted) {
            _controller.charger();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(String nomAtelier) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: KColors.indigo,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getSalutation(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: KColors.brassLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Atelier : $nomAtelier',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(AccueilData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              num: '${data.enCours}',
              label: 'commandes en cours',
              accent: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(num: '${data.pretes}', label: 'prêtes à livrer'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String num;
  final String label;
  final bool accent;

  const _StatCard({
    required this.num,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: accent ? KColors.terracotta : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent ? KColors.terracotta : KColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            num,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: accent ? Colors.white : KColors.indigo,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: accent ? Colors.white70 : KColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandeTile extends StatelessWidget {
  final CommandeModel commande;
  final VoidCallback onrefresh;
  const _CommandeTile({required this.commande, required this.onrefresh});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaiementCommandePage(commandeId: commande.id),
          ),
        );
        onrefresh();
      },
      leading: CircleAvatar(
        backgroundColor: KColors.indigo,
        child: Text(
          commande.clientNom.isNotEmpty ? commande.clientNom[0] : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(
        commande.clientNom,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        commande.typeVetement,
        style: const TextStyle(fontSize: 11, color: KColors.muted),
      ),
      trailing: StatutBadge(statut: commande.statut),
    );
  }
}
