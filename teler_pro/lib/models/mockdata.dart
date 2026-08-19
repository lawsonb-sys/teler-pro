import 'package:teler_pro/models/model.dart';

/// Jeu de données fictives pour construire et tester l'UI
/// avant de brancher PocketBase. À supprimer une fois le backend connecté.
class MockData {
  static final clients = [
    ClientModel(id: 'c1', nom: 'Ama Dogbé', telephone: '90 12 34 56'),
    ClientModel(id: 'c2', nom: 'Kossi Mensah', telephone: '91 22 33 44'),
    ClientModel(id: 'c3', nom: 'Efua Yao', telephone: '92 55 66 77'),
    ClientModel(id: 'c4', nom: 'Sena Nyavor', telephone: '93 88 99 00'),
  ];

  static final mesureAma = MesureModel(
    clientId: 'c1',
    tourPoitrine: 96,
    tourTaille: 78,
    tourBassin: 104,
    longueurRobe: 128,
    longueurManche: 57,
    tourBras: 29,
  );

  static final commandes = [
    CommandeModel(
      id: 'o1',
      clientId: 'c1',
      clientNom: 'Ama Dogbé',
      typeVetement: 'Robe pagne',
      tissu: 'Wax bleu',
      prixTotal: 25000,
      statut: 'en_cours',
      dateLivraisonPrevue: DateTime(2026, 8, 14),
      montantPaye: 10000,
    ),
    CommandeModel(
      id: 'o2',
      clientId: 'c2',
      clientNom: 'Kossi Mensah',
      typeVetement: 'Costume 2 pièces',
      tissu: 'Laine grise',
      prixTotal: 60000,
      statut: 'pret',
      dateLivraisonPrevue: DateTime(2026, 8, 12),
      montantPaye: 60000,
    ),
    CommandeModel(
      id: 'o3',
      clientId: 'c3',
      clientNom: 'Efua Yao',
      typeVetement: 'Ensemble boubou',
      tissu: 'Brodé',
      prixTotal: 35000,
      statut: 'attente',
      dateLivraisonPrevue: DateTime(2026, 8, 20),
      montantPaye: 0,
    ),
    CommandeModel(
      id: 'o4',
      clientId: 'c4',
      clientNom: 'Sena Nyavor',
      typeVetement: 'Chemise sur-mesure',
      tissu: 'Coton blanc',
      prixTotal: 15000,
      statut: 'en_cours',
      dateLivraisonPrevue: DateTime(2026, 8, 18),
      montantPaye: 5000,
    ),
  ];

  static final paiementsCommande1 = [
    PaiementModel(
      id: 'p1',
      montant: 10000,
      mode: 'tmoney',
      createdAt: DateTime(2026, 8, 2),
    ),
  ];

  static const nomAtelier = 'Atelier Koffi';
}
