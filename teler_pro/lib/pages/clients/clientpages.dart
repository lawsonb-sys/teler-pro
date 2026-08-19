import 'package:flutter/material.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/pages/clients/ficheclients.dart';
import 'package:teler_pro/pages/clients/nvclpage.dart';

class ClientsPages extends StatefulWidget {
  const ClientsPages({super.key});

  @override
  State<ClientsPages> createState() => _ClientsPagesState();
}

class _ClientsPagesState extends State<ClientsPages> {
  late Future<List<ClientModel>> _future;
  int _nombreCommandes = 0;
  @override
  void initState() {
    super.initState();
    _future = _charger();
  }

  Future<List<ClientModel>> _charger() async {
    final atelier = await atelierService.atelierCourant();
    final records = await pb
        .collection('clients')
        .getFullList(filter: 'atelier = "${atelier.id}"', sort: 'nom');
    return records.map((r) => ClientModel.fromMap(r.data)).toList();
  }

  Future<void> _nombrecmd(String clientId) async {
    final commandesRecords = await pb
        .collection('commandes')
        .getFullList(filter: 'client = "$clientId"', sort: '-created');
    final commandes = commandesRecords
        .map((r) => CommandeModel.fromRecord(r))
        .toList();
    _nombreCommandes = commandes.length;
  }

  Future<void> _rafraichir() async {
    setState(() => _future = _charger());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: FutureBuilder<List<ClientModel>>(
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
          final clients = snap.data!;

          return RefreshIndicator(
            onRefresh: _rafraichir,
            child: clients.isEmpty
                ? ListView(
                    // ListView (même avec 1 seul enfant) au lieu de Center :
                    // RefreshIndicator a besoin d'un widget défilable pour
                    // détecter le geste "tirer vers le bas", même à vide.
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Text(
                            'Aucun client pour l\'instant\nAppuie sur + pour en ajouter un',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: KColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, i) {
                      final client = clients[i];
                      _nombrecmd(client.id);
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Material(
                          color: Colors.white,
                          elevation: 1.0,
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),

                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: KColors.indigo,
                                child: Text(
                                  client.nom.isNotEmpty ? client.nom[0] : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                client.nom,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                client.telephone ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: KColors.muted,
                                ),
                              ),
                              trailing: CircleAvatar(
                                backgroundColor: KColors.indigo,
                                child: Text(
                                  '$_nombreCommandes',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FicheClientPage(clientId: client.id),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final cree = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const NouveauClientPage()),
          );
          if (cree == true) _rafraichir();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
