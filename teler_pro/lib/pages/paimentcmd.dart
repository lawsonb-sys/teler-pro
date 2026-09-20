import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 Import Riverpod
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:teler_pro/controlers/commande_ctr.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/providers.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/repo/offline_repo.dart';

// 1. Conversion en ConsumerStatefulWidget
class PaiementCommandePage extends ConsumerStatefulWidget {
  final String commandeId;
  const PaiementCommandePage({super.key, required this.commandeId});

  @override
  ConsumerState<PaiementCommandePage> createState() =>
      _PaiementCommandePageState();
}

class _PaiementCommandePageState extends ConsumerState<PaiementCommandePage> {
  final _montantCtrl = TextEditingController();
  String _modeSelectionne = 'tmoney';
  bool _envoiEnCours = false;
  late Future<_PaiementData> _future;

  // Dépôts locaux Hive
  final _commandesRepo = OfflineRepository('commandes');
  final _paiementsRepo = OfflineRepository('paiements');
  final _clientsRepo = OfflineRepository('clients');

  @override
  void initState() {
    super.initState();
    _future = _charger();
    _actualiserArrierePlan();
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    super.dispose();
  }

  Future<void> _actualiserArrierePlan() async {
    try {
      await _clientsRepo.actualiser();
      await _commandesRepo.actualiser();
      await _paiementsRepo.actualiser(
        filter: 'commande = "${widget.commandeId}"',
      );
      if (mounted) {
        setState(() => _future = _charger());
      }
    } catch (_) {}
  }

  Future<_PaiementData> _charger() async {
    final cacheClients = await _clientsRepo.lireCache();
    final Map<String, String> mapClients = {
      for (var c in cacheClients)
        c['id'].toString(): (c['nom'] ?? c['nom_client'] ?? 'Client inconnu')
            .toString(),
    };

    final cacheCommandes = await _commandesRepo.lireCache();
    final commandeMap = cacheCommandes.firstWhere(
      (c) => c['id'] == widget.commandeId,
      orElse: () => {},
    );

    if (commandeMap.isEmpty) {
      throw Exception("Commande introuvable dans le cache local.");
    }

    final commandeMapComplete = Map<String, dynamic>.from(commandeMap);
    final clientId = commandeMapComplete['client']?.toString() ?? '';

    if (!commandeMapComplete.containsKey('clientNom') ||
        commandeMapComplete['clientNom'] == null ||
        commandeMapComplete['clientNom'] == '—') {
      commandeMapComplete['clientNom'] = mapClients[clientId] ?? '—';
    }

    final cachePaiements = await _paiementsRepo.lireCache();
    final paiements = cachePaiements
        .where((p) => p['commande'] == widget.commandeId)
        .map((p) => PaiementModel.fromCacheMap(p))
        .toList();

    paiements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final montantPaye = paiements.fold<double>(0, (s, p) => s + p.montant);
    final commande = CommandeModel.fromCacheMap(
      commandeMapComplete,
      montantPaye: montantPaye,
    );

    return _PaiementData(commande: commande, paiements: paiements);
  }

  // 🚀 Méthode de changement de statut réactivée et optimisée
  Future<void> _changerStatutCommande(CommandeModel commande) async {
    final statuts = [
      {'code': 'attente', 'label': 'En attente'},
      {'code': 'en_cours', 'label': 'En cours'},
      {'code': 'pret', 'label': 'Prêt à livrer'},
      {'code': 'livre', 'label': 'Livré'},
    ];

    final nouveauStatut = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Changer le statut',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: KColors.indigo,
                ),
              ),
            ),
            const Divider(),
            ...statuts.map(
              (s) => ListTile(
                title: Text(s['label']!),
                trailing: commande.statut.toLowerCase() == s['code']
                    ? const Icon(Icons.check_circle, color: KColors.indigo)
                    : null,
                onTap: () => Navigator.pop(ctx, s['code']),
              ),
            ),
          ],
        ),
      ),
    );

    if (nouveauStatut != null && nouveauStatut != commande.statut) {
      try {
        await _commandesRepo.modifier(commande.id, {'statut': nouveauStatut});

        // 💡 Utilisation de ref.read pour notifier l'ensemble de l'appli
        final ctr = ref.read(commandesControllerProvider);
        final index = ctr.commandes.indexWhere((c) => c.id == commande.id);
        if (index != -1) {
          ctr.commandes[index] = ctr.commandes[index].copyWith(
            statut: nouveauStatut,
          );
          ctr.notifyListeners(); // Rafraîchit aussi les autres pages à l'écoute !
        }

        // Mise à jour de l'affichage local instantanément
        final dataActuelle = await _future;
        final commandeModifiee = CommandeModel(
          id: dataActuelle.commande.id,
          clientId: dataActuelle.commande.clientId,
          clientNom: dataActuelle.commande.clientNom,
          typeVetement: dataActuelle.commande.typeVetement,
          tissu: dataActuelle.commande.tissu,
          prixTotal: dataActuelle.commande.prixTotal,
          statut: nouveauStatut,
          dateLivraisonPrevue: dataActuelle.commande.dateLivraisonPrevue,
          montantPaye: dataActuelle.commande.montantPaye,
          enAttente: dataActuelle.commande.enAttente,
        );

        setState(() {
          _future = Future.value(
            _PaiementData(
              commande: commandeModifiee,
              paiements: dataActuelle.paiements,
            ),
          );
        });

        _actualiserArrierePlan();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Statut mis à jour : $nouveauStatut'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: KColors.terracotta,
            ),
          );
        }
      }
    }
  }

  Future<void> _enregistrerPaiement() async {
    final montant = double.tryParse(_montantCtrl.text.replaceAll(' ', ''));
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saisir un montant valide')));
      return;
    }

    setState(() => _envoiEnCours = true);

    try {
      await _paiementsRepo.creer({
        'commande': widget.commandeId,
        'montant': montant,
        'mode': _modeSelectionne,
      });

      _montantCtrl.clear();
      FocusScope.of(context).unfocus();
      setState(() => _future = _charger());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement enregistré avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Écoute de Riverpod
    ref.watch(commandesControllerProvider);

    final fmt = NumberFormat.decimalPattern('fr');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: SafeArea(
          top: true,
          bottom: false,
          child: FutureBuilder<_PaiementData>(
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
              final c = data.commande;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHero(context, c, fmt)),
                  SliverToBoxAdapter(child: _buildSplitBar(c, fmt)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                      child: Text(
                        'HISTORIQUE DES PAIEMENTS',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: KColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (data.paiements.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        child: Text(
                          'Aucun paiement enregistré',
                          style: TextStyle(color: KColors.muted, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    SliverList.builder(
                      itemCount: data.paiements.length,
                      itemBuilder: (context, i) {
                        final p = data.paiements[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.modeLabel,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'd MMM yyyy',
                                      'fr',
                                    ).format(p.createdAt),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: KColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '+${fmt.format(p.montant)} FCFA',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: KColors.threadGreen,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  SliverToBoxAdapter(child: _buildAjoutPaiement(context)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, CommandeModel c, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: KColors.indigo,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.arrow_back, color: KColors.brassLight),
              ),
              InkWell(
                onTap: () => _changerStatutCommande(c),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      StatutBadge(statut: c.statut),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit,
                        size: 14,
                        color: KColors.brassLight,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${c.clientNom} · ${c.typeVetement}',
            style: const TextStyle(fontSize: 11, color: Color(0xFFB7C2D2)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Column(
              children: [
                Text(
                  '${fmt.format(c.prixTotal)} FCFA',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'PRIX TOTAL DE LA COMMANDE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: KColors.brassLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitBar(CommandeModel c, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: c.progression,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDE6D5),
              valueColor: const AlwaysStoppedAnimation(KColors.threadGreen),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payé ${fmt.format(c.montantPaye)} FCFA',
                style: const TextStyle(fontSize: 10, color: KColors.muted),
              ),
              Text(
                'Reste dû ${fmt.format(c.soldeDu)} FCFA',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: KColors.terracotta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAjoutPaiement(BuildContext context) {
    final modes = const [
      ('tmoney', 'T-Money'),
      ('flooz', 'Flooz'),
      ('especes', 'Espèces'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENREGISTRER UN PAIEMENT',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              color: KColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _montantCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Montant reçu — FCFA',
              filled: true,
              fillColor: KColors.ecru,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: modes.map((m) {
              final (value, label) = m;
              final selectionne = _modeSelectionne == value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _modeSelectionne = value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selectionne
                            ? const Color(0xFFEEF1F6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectionne
                              ? KColors.indigo
                              : KColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: selectionne ? KColors.indigo : KColors.muted,
                          fontWeight: selectionne
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _envoiEnCours ? null : _enregistrerPaiement,
              child: _envoiEnCours
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaiementData {
  final CommandeModel commande;
  final List<PaiementModel> paiements;
  _PaiementData({required this.commande, required this.paiements});
}
