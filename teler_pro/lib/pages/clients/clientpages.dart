import 'package:flutter/material.dart';
import 'package:teler_pro/controlers/client_ctr.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/pages/clients/ficheclients.dart';
import 'package:teler_pro/pages/clients/nvclpage.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final _controller = ClientsController()..charger();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _buildCorps(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NouveauClientPage(controller: _controller),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCorps() {
    if (_controller.erreur != null) {
      return Center(
        child: Text(
          _controller.erreur!,
          style: const TextStyle(color: KColors.terracotta),
        ),
      );
    }
    if (_controller.chargement && _controller.clients.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final clients = _controller.clients;
    return RefreshIndicator(
      onRefresh: _controller.charger,
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
          : ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, i) {
                final client = clients[i];
                return _ClientTile(
                  client: client,
                  onTap: () async {
                    if (client.enAttente) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ce client sera synchronisé dès que la connexion revient',
                          ),
                        ),
                      );
                      return;
                    }
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FicheClientPage(clientId: client.id),
                      ),
                    );
                    _controller.charger();
                  },
                );
              },
            ),
    );
  }
}

// Widget séparé pour gérer le comptage des commandes par client
class _ClientTile extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onTap;

  const _ClientTile({required this.client, required this.onTap});

  Future<int> _getNombreCommandes(String clientId) async {
    final records = await pb
        .collection('commandes')
        .getFullList(filter: 'client = "$clientId"');
    return records.length;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  final count = snapshot.data ?? 0;
                  return Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: KColors.indigo,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
