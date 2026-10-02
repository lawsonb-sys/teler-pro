import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teler_pro/controlers/command_ctr/commande_ctr.dart';
import 'package:teler_pro/controlers/users/user_ctr.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';
import 'package:teler_pro/outils/exp.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/pages/commandes/nvcommande.dart';
import 'package:teler_pro/pages/paimentcmd.dart';
import 'package:teler_pro/provider/test_ctr.dart';
import 'package:teler_pro/services/connectivity_service.dart';

import '../models/pocketbase.dart';
import '../outils/dialogue.dart';
import '../outils/pockethealth.dart';

class AccueilScreen extends ConsumerStatefulWidget {
  const AccueilScreen({super.key});

  @override
  ConsumerState<AccueilScreen> createState() => _AccueilScreenState();
}

class _AccueilScreenState extends ConsumerState<AccueilScreen> {
  // Vous pouvez déclarer ici vos contrôleurs, initState, dispose ou état local si besoin.

  @override
  void initState() {
    super.initState();
    // Initialisations si nécessaire
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifierConnexion();
    });
  }

  @override
  void dispose() {
    // Nettoyage si nécessaire
    super.dispose();
  }

  /// Verifaction de la connnectivivité
  Future<void> _verifierConnexion() async {
    final aDuReseau = await connectivityService.estConnecte();
    if (!mounted) return;
    if (!aDuReseau) {
      afficherSnackBar(
        context: context,
        message: 'Aucune connexion internet disponible',
        couleur: Colors.orange,
        icone: Icons.wifi_off,
      );
      return;
    }
    final serveurAceesible = await pb.estServeurAccessible();
    if (!mounted) return;
    if (serveurAceesible) {
      afficherSnackBar(
        context: context,
        message: 'Connecté au serveur PocketBase',
        couleur: Colors.green,
        icone: Icons.cloud_done,
      );
      return;
    } else {
      afficherSnackBar(
        context: context,
        message: 'Connecté au réseau , mais la base est hors-ligne',
        couleur: Colors.red,
        icone: Icons.cloud_off,
      );
    }
  }

  /// Salutation dynamique selon l'heure du jour
  String get _salutation {
    final heure = DateTime.now().hour;
    if (heure >= 18 || heure < 5) {
      return 'BONSOIR';
    }
    return 'BONJOUR';
  }

  @override
  Widget build(BuildContext context) {
    // Note : ref est directement accessible ici dans toute la classe d'état (ConsumerState)
    final asyncAccueil = ref.watch(accueilControllerProvider);
    final nomAtelier = ref.watch(nomAtelierProvider);

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: AtelierService().atelierCourant(),
        builder: (context, snapshotAtelier) {
          return asyncAccueil.when(
            // -------------------------------------------------------------
            // CAS 1 : DONNÉES CHARGÉES DÉPUIS LE CACHE / RÉSEAU
            // -------------------------------------------------------------
            data: (data) {
              final commandes = data.commandes;
              final enCours = commandes
                  .where((c) => c.statut == 'en_cours')
                  .length;
              final pretes = commandes.where((c) => c.statut == 'pret').length;

              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(accueilControllerProvider.notifier).rafraichir(),
                child: CustomScrollView(
                  slivers: [
                    // 1. En-tête personnalisé (Hero)
                    SliverToBoxAdapter(child: _buildHeader(nomAtelier)),

                    // 2. Cartes de statistiques
                    SliverToBoxAdapter(
                      child: _buildStats(enCours: enCours, pretes: pretes),
                    ),

                    // 3. Titre de section
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(18, 20, 18, 8),
                        child: Text(
                          'COMMANDES RÉCENTES',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            color: KColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // 4. Liste des commandes récentes ou message si vide
                    if (commandes.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "Aucune commande pour l'instant",
                            style: TextStyle(
                              color: KColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList.builder(
                        itemCount: commandes.length,
                        itemBuilder: (context, i) =>
                            _CommandeTile(commande: commandes[i]),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 90)),
                  ],
                ),
              );
            },

            // -------------------------------------------------------------
            // CAS 2 : CHARGEMENT INITIAL
            // -------------------------------------------------------------
            loading: () => const Center(child: CircularProgressIndicator()),

            // -------------------------------------------------------------
            // CAS 3 : ERREUR
            // -------------------------------------------------------------
            error: (erreur, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'Erreur : $erreur',
                    style: const TextStyle(color: KColors.terracotta),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(accueilControllerProvider.notifier)
                        .rafraichir(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // Floating Action Button pour ajouter une nouvelle commande
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_accueil_nouvelle_commande',
        onPressed: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const NouvelleCommandePage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// En-tête personnalisé bleu indigo
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
            _salutation,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: KColors.brassLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'Atelier : ',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: KColors.brassLight,
                ),
              ),
              Text(
                nomAtelier,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section des statistiques
  Widget _buildStats({required int enCours, required int pretes}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              num: '$enCours',
              label: 'commandes en cours',
              accent: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(num: '$pretes', label: 'prêtes à livrer'),
          ),
        ],
      ),
    );
  }
}

/// Carte individuelle de statistique
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

/// Élément de liste pour une commande récente
class _CommandeTile extends StatelessWidget {
  final CommandeModel commande;

  const _CommandeTile({required this.commande});

  @override
  Widget build(BuildContext context) {
    final initiale = commande.clientNom.isNotEmpty
        ? commande.clientNom[0].toUpperCase()
        : '?';

    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaiementCommandePage(commandeId: commande.id),
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: KColors.indigo,
        child: Text(
          initiale,
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
