import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/mesure_template.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/pages/clients/mesureform.dart';
import 'package:teler_pro/pages/commandes/nvcommande.dart';
import 'package:teler_pro/pages/paimentcmd.dart';
import 'package:teler_pro/repo/offline_repo.dart';

class FicheClientPage extends StatefulWidget {
  final String clientId;
  const FicheClientPage({super.key, required this.clientId});

  @override
  State<FicheClientPage> createState() => _FicheClientPageState();
}

class _FicheClientPageState extends State<FicheClientPage> {
  late Future<_FicheData> _future;

  final _clientsRepo = OfflineRepository('clients');
  final _commandesRepo = OfflineRepository('commandes');
  final _mesuresRepo = OfflineRepository('mesures');

  @override
  void initState() {
    super.initState();
    _future = _charger();
    _actualiserArrierePlan();
  }

  Future<void> _actualiserArrierePlan() async {
    try {
      await _clientsRepo.actualiser();
      await _commandesRepo.actualiser(filter: 'client = "${widget.clientId}"');
      await _mesuresRepo.actualiser(filter: 'client = "${widget.clientId}"');
    } catch (_) {}
  }

  Future<_FicheData> _charger() async {
    // 1. Lire le client dans Hive local
    final cacheClients = await _clientsRepo.lireCache();
    final clientMap = cacheClients.firstWhere(
      (c) => c['id'] == widget.clientId,
      orElse: () => {},
    );

    if (clientMap.isEmpty) {
      throw Exception("Client introuvable dans le cache local.");
    }
    final client = ClientModel.fromCacheMap(clientMap);

    // 2. Lire les commandes du client dans Hive local
    final cacheCommandes = await _commandesRepo.lireCache();
    final commandes = cacheCommandes
        .where((c) => c['client'] == widget.clientId)
        .map((c) => CommandeModel.fromCacheMap(c))
        .toList();

    return _FicheData(client: client, commandes: commandes);
  }

  /// Recharge la fiche client locale et en arrière-plan
  Future<void> _rafraichirPage() async {
    setState(() {
      _future = _charger();
    });
    await _actualiserArrierePlan();
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
                onRefresh: _rafraichirPage,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHero(
                        context,
                        data.client,
                        data.commandes.length,
                      ),
                    ),

                    // SECTION MESURES
                    SliverToBoxAdapter(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _mesuresRepo.ecouterCache(),
                        builder: (context, snapshot) {
                          final toutesLesMesures = snapshot.data ?? [];
                          final mesuresClient = toutesLesMesures
                              .where((m) => m['client'] == widget.clientId)
                              .map((m) => MesureModel.fromCacheMap(m))
                              .toList();

                          return _buildMesuresSection(context, mesuresClient);
                        },
                      ),
                    ),

                    // HISTORIQUE COMMANDES
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
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PaiementCommandePage(commandeId: c.id),
                                  ),
                                );
                                _rafraichirPage();
                              },
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
                            if (cree == true || mounted) _rafraichirPage();
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

  // Boîte de dialogue de modification du client
  void _afficherFormulaireModification(
    BuildContext context,
    ClientModel client,
  ) {
    final nomController = TextEditingController(text: client.nom);
    final telephoneController = TextEditingController(text: client.telephone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le client'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du client',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KColors.indigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final donneesModifiees = {
                'nom': nomController.text.trim(),
                'telephone': telephoneController.text.trim(),
              };

              try {
                // 1. Modification via le repository
                await _clientsRepo.modifier(client.id, donneesModifiees);

                if (ctx.mounted) {
                  Navigator.pop(ctx);

                  // 2. Recharge l'affichage immédiatement
                  _rafraichirPage();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client modifié avec succès')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
          CircleAvatar(
            radius: 20,
            backgroundColor: KColors.brassLight,
            child: IconButton(
              onPressed: () {
                _afficherFormulaireModification(context, client);
              },
              icon: const Icon(Icons.edit, size: 20, color: KColors.indigo),
            ),
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
                Row(
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
                    if (mesure.enAttente) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFE1C6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 10,
                              color: Color(0xFF8A6A1F),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'En attente',
                              style: TextStyle(
                                fontSize: 8,
                                color: Color(0xFF8A6A1F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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
                      icon: const Icon(
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
      builder: (_) => ListView(
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
    );
    if (choix != null) {
      _ouvrirFormulaireMesures(typeVetementInitial: choix);
    }
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
            child: const Text(
              'Supprimer',
              style: TextStyle(color: KColors.terracotta),
            ),
          ),
        ],
      ),
    );

    if (confirme == true && mesure.id != null) {
      try {
        await _mesuresRepo.supprimer(mesure.id!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
        }
      }
    }
  }

  Future<void> _ouvrirFormulaireMesures({
    MesureModel? mesureExistante,
    String? typeVetementInitial,
  }) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MesuresFormPage(
          clientId: widget.clientId,
          mesuresRepo: _mesuresRepo,
          mesureExistante: mesureExistante,
          typeVetementInitial: typeVetementInitial,
        ),
      ),
    );
  }
}

class _FicheData {
  final ClientModel client;
  final List<CommandeModel> commandes;

  _FicheData({required this.client, required this.commandes});
}
