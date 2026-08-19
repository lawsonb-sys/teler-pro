import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/pages/clients/mesureform.dart';
import 'package:teler_pro/pages/commandes/nvcommande.dart';
import 'package:teler_pro/pages/paimentcmd.dart';

class FicheClientPage extends StatefulWidget {
  final String clientId;
  const FicheClientPage({super.key, required this.clientId});

  @override
  State<FicheClientPage> createState() => _FicheClientPageState();
}

class _FicheClientPageState extends State<FicheClientPage> {
  late Future<_FicheData> _future;

  @override
  void initState() {
    super.initState();
    _future = _charger();
  }

  Future<_FicheData> _charger() async {
    final clientRecord = await pb.collection('clients').getOne(widget.clientId);
    final client = ClientModel.fromRecord(clientRecord);

    // La fiche de mesures est optionnelle : getFirstListItem lève une
    // ClientException (404) s'il n'y en a pas encore — on l'intercepte.
    MesureModel? mesure;
    try {
      final mesureRecord = await pb
          .collection('mesures')
          .getFirstListItem('client = "${widget.clientId}"');
      mesure = MesureModel.fromRecord(mesureRecord);
    } on ClientException catch (e) {
      if (e.statusCode != 404) rethrow;
      mesure = null;
    }

    final commandesRecords = await pb
        .collection('commandes')
        .getFullList(filter: 'client = "${widget.clientId}"', sort: '-created');
    final commandes = commandesRecords
        .map((r) => CommandeModel.fromRecord(r))
        .toList();

    return _FicheData(client: client, mesure: mesure, commandes: commandes);
  }

  Future<void> _rafraichir() async {
    setState(() => _future = _charger());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          top: true,
          bottom: false,
          child: FutureBuilder<_FicheData>(
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
              return RefreshIndicator(
                onRefresh: _rafraichir,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHero(
                        context,
                        data.client,
                        data.commandes.length,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildMesuresCard(context, data.mesure),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                        child: Text(
                          'HISTORIQUE',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            color: KColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (data.commandes.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            'Aucune commande pour ce client',
                            style: TextStyle(
                              color: KColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList.builder(
                        itemCount: data.commandes.length,
                        itemBuilder: (context, i) {
                          final c = data.commandes[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: ListTile(
                              title: Text(
                                c.typeVetement,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                c.tissu ?? '',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: KColors.muted,
                                ),
                              ),
                              trailing: StatutBadge(statut: c.statut),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PaiementCommandePage(commandeId: c.id),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: ElevatedButton(
                          onPressed: () async {
                            final cree = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NouvelleCommandePage(
                                  clientIdPreselectionne: data.client.id,
                                ),
                              ),
                            );
                            if (cree == true) _rafraichir();
                          },
                          child: const Text('Nouvelle commande'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, ClientModel client, int nbCommandes) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: const BoxDecoration(
        color: KColors.indigo,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
          const SizedBox(height: 10),
          Text(
            client.nom,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$nbCommandes commande${nbCommandes > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 11, color: Color(0xFFB7C2D2)),
          ),
        ],
      ),
    );
  }

  Widget _buildMesuresCard(BuildContext context, MesureModel? mesure) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KColors.cardBorder),
        ),
        child: Column(
          children: [
            if (mesure == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Aucune mesure enregistrée',
                        style: TextStyle(color: KColors.muted, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _ouvrirFormulaireMesures(mesure),
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              )
            else ...[
              ...mesure.lignes.map((ligne) {
                final (label, valeur) = ligne;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: KColors.cardBorder, width: 0.7),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5C554A),
                        ),
                      ),
                      Text(
                        valeur != null
                            ? '${valeur.toStringAsFixed(0)} cm'
                            : '—',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: KColors.indigo,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextButton(
                  onPressed: () => _ouvrirFormulaireMesures(mesure),
                  child: const Text('Modifier'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _ouvrirFormulaireMesures(MesureModel? mesureExistante) async {
    final modifie = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MesuresFormPage(
          clientId: widget.clientId,
          mesureExistante: mesureExistante,
        ),
      ),
    );
    if (modifie == true && mounted) _rafraichir();
  }
}

class _FicheData {
  final ClientModel client;
  final MesureModel? mesure;
  final List<CommandeModel> commandes;

  _FicheData({
    required this.client,
    required this.mesure,
    required this.commandes,
  });
}
