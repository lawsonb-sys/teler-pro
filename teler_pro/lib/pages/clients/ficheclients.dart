import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/mesure_template.dart';
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

    final mesuresRecords = await pb
        .collection('mesures')
        .getFullList(filter: 'client = "${widget.clientId}"');
    final mesures = mesuresRecords
        .map((r) => MesureModel.fromRecord(r))
        .toList();

    final commandesRecords = await pb
        .collection('commandes')
        .getFullList(filter: 'client = "${widget.clientId}"', sort: '-created');
    final commandes = commandesRecords
        .map((r) => CommandeModel.fromRecord(r))
        .toList();

    return _FicheData(client: client, mesures: mesures, commandes: commandes);
  }

  Future<void> _rafraichir() async {
    setState(() {
      _future = _charger();
    });
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
                      child: _buildMesuresSection(context, data.mesures),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(18, 20, 18, 8),
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
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18),
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
            icon: const Icon(Icons.arrow_back, color: KColors.brassLight),
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

  Widget _buildMesuresSection(BuildContext context, List<MesureModel> mesures) {
    return Column(
      children: [
        for (final mesure in mesures) ...[
          const SizedBox(height: 14),
          _buildMesureCard(context, mesure),
        ],
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: () => _choisirTypeEtAjouter(context, mesures),
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              mesures.isEmpty
                  ? 'Ajouter des mesures'
                  : 'Ajouter un autre type de vêtement',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMesureCard(BuildContext context, MesureModel mesure) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KColors.cardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  MesureTemplates.labelType[mesure.typeVetement] ??
                      mesure.typeVetement,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: KColors.indigo,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () =>
                          _ouvrirFormulaireMesures(mesureExistante: mesure),
                      child: const Text('Modifier'),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: KColors.terracotta,
                      ),
                      onPressed: () => _confirmerSuppression(context, mesure),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ...mesure.lignes.map((ligne) {
            final (label, valeur) = ligne;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
                    valeur != null ? '${valeur.toStringAsFixed(0)} cm' : '—',
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
        ],
      ),
    );
  }

  Future<void> _confirmerSuppression(
    BuildContext context,
    MesureModel mesure,
  ) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette fiche ?'),
        content: Text(
          'La fiche de mesures "${MesureTemplates.labelType[mesure.typeVetement] ?? mesure.typeVetement}" sera définitivement supprimée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Supprimer',
              style: TextStyle(color: KColors.terracotta),
            ),
          ),
        ],
      ),
    );

    if (confirme == true && mesure.id != null) {
      try {
        await pb.collection('mesures').delete(mesure.id!);
        if (mounted) _rafraichir();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
        }
      }
    }
  }

  Future<void> _choisirTypeEtAjouter(
    BuildContext context,
    List<MesureModel> mesuresExistantes,
  ) async {
    final typesDejaPresents = mesuresExistantes
        .map((m) => m.typeVetement)
        .toSet();
    final typesRestants = MesureTemplates.labelType.entries
        .where((e) => !typesDejaPresents.contains(e.key))
        .toList();

    if (typesRestants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tous les types de vêtement ont déjà une fiche de mesures',
          ),
        ),
      );
      return;
    }

    final choix = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: typesRestants
              .map(
                (e) => ListTile(
                  title: Text(e.value),
                  onTap: () => Navigator.pop(context, e.key),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (choix != null) {
      _ouvrirFormulaireMesures(typeVetementInitial: choix);
    }
  }

  Future<void> _ouvrirFormulaireMesures({
    MesureModel? mesureExistante,
    String? typeVetementInitial,
  }) async {
    final modifie = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MesuresFormPage(
          clientId: widget.clientId,
          mesureExistante: mesureExistante,
          typeVetementInitial: typeVetementInitial,
        ),
      ),
    );
    if (modifie == true && mounted) _rafraichir();
  }
}

class _FicheData {
  final ClientModel client;
  final List<MesureModel> mesures;
  final List<CommandeModel> commandes;

  _FicheData({
    required this.client,
    required this.mesures,
    required this.commandes,
  });
}
