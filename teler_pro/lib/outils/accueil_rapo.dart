// lib/repositories/accueil_repository.dart
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';

class AccueilData {
  final String nomAtelier;
  final List<CommandeModel> commandes;
  final int enCours;
  final int pretes;

  AccueilData({
    required this.nomAtelier,
    required this.commandes,
    required this.enCours,
    required this.pretes,
  });
}

class AccueilRepository {
  Future<AccueilData> chargers() async {
    final atelier = await atelierService.atelierCourant();
    print('Atelier courant : ${atelier}');
    // On entoure la requête d'un bloc try/catch local
    List<RecordModel> items = [];
    try {
      final commandesRecords = await pb
          .collection('commandes')
          .getList(
            page: 1,
            perPage: 6,
            filter: 'atelier = "${atelier.id}"',
            sort: '-created',
            expand: 'client',
          );
      items = commandesRecords.items;
    } catch (e) {
      // Si la base est vide ou si l'expand échoue, on continue avec une liste vide
      debugPrint('Aucune commande ou erreur PocketBase : $e');
      items = [];
    }

    final commandes = <CommandeModel>[];
    for (final r in items) {
      // On sécurise aussi la recherche de paiements
      List<RecordModel> paiements = [];
      try {
        paiements = await pb
            .collection('paiements')
            .getFullList(filter: 'commande = "${r.id}"');
      } catch (_) {}

      final montantPaye = paiements.fold<double>(
        0,
        (s, p) => s + ((p.data['montant'] ?? 0) as num).toDouble(),
      );
      commandes.add(CommandeModel.fromRecord(r, montantPaye: montantPaye));
    }

    final enCours = commandes.where((c) => c.statut == 'en_cours').length;
    final pretes = commandes.where((c) => c.statut == 'pret').length;

    return AccueilData(
      nomAtelier: atelier.getStringValue('nom'),
      commandes: commandes,
      enCours: enCours,
      pretes: pretes,
    );
  }
}
