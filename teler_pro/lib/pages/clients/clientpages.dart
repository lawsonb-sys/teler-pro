import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:teler_pro/controlers/clients_ctr/clients_controller.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/pages/clients/ficheclients.dart';
import 'package:teler_pro/pages/clients/nvclpage.dart';
import 'package:teler_pro/repo/offline_repo.dart';

import '../../outils/dialogue.dart';

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  @override
  Widget build(BuildContext context) {
    final stateclient = ref.watch(clientsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: SafeArea(
        child: stateclient.when(
          data: (data) => _buildCorps(data),
          error: (error, stackTrace) => Center(
            child: Text(
              'Erreur: $error',
              style: const TextStyle(color: KColors.terracotta),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NouveauClientPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCorps(List<ClientModel> clients) {
    final controller = ref.read(clientsControllerProvider.notifier);

    return RefreshIndicator(
      onRefresh: controller.rafraichir,
      child: clients.isEmpty
          ? ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: Text(
                'Aucun client pour l\'instant\nAppuie sur + pour en ajouter un',
                textAlign: TextAlign.center,
                style: TextStyle(color: KColors.muted, fontSize: 13),
              ),
            ),
          ),
        ],
      )
          : AnimationLimiter(
        child: ListView.builder(
          itemCount: clients.length,
          itemBuilder: (context, i) {
            final client = clients[i];
            return AnimationConfiguration.staggeredList(
              position: i,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _ClientTile(
                    client: client,
                    onTap: () async {
                      if (client.enAttente) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Client local : sera synchronisé au retour de la connexion',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FicheClientPage(clientId: client.id),
                        ),
                      );

                      if (!context.mounted) return;
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Transformé en ConsumerWidget pour avoir accès à `ref`
class _ClientTile extends ConsumerWidget {
  final ClientModel client;
  final VoidCallback onTap;

  const _ClientTile({required this.client, required this.onTap});

  Future<int> _getNombreCommandes(String clientId) async {
    try {
      final commandesBrutes = await OfflineRepository('commandes').lireCache();
      return commandesBrutes.where((cmd) => cmd['client'] == clientId).length;
    } catch (_) {
      return 0;
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(client.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final reponse = await afficherDialogue(context,'Voulez-vous vraiment supprimer ce client ?');
        return reponse ?? false;
      },
      onDismissed: (direction) {
        // Appelle la méthode dans le controller
        ref.read(clientsControllerProvider.notifier).supprimerClient(client.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_sweep,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: client.enAttente ? KColors.muted : KColors.indigo,
            child: Text(
              client.nom.isNotEmpty ? client.nom[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            client.nom,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            client.telephone ?? '',
            style: const TextStyle(fontSize: 12, color: KColors.muted),
          ),
          trailing: client.enAttente
              ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFE1C6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 12, color: Color(0xFF8A6A1F)),
                SizedBox(width: 4),
                Text(
                  'En attente',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A6A1F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
              : FutureBuilder<int>(
            future: _getNombreCommandes(client.id),
            builder: (context, snapshot) {
              return SizedBox(
                width: 29,
                height: 29,
                child: Center(
                  child: CircleAvatar(
                    radius: 30.0,
                    child: Text('${snapshot.data ?? 0}'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}