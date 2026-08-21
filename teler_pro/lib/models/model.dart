import 'package:pocketbase/pocketbase.dart';

class ClientModel {
  final String id;
  final String nom;
  final String? telephone;

  ClientModel({required this.id, required this.nom, this.telephone});

  factory ClientModel.fromMap(Map<String, dynamic> m) => ClientModel(
    id: m['id'] as String,
    nom: m['nom'] as String,
    telephone: m['telephone'] as String?,
  );

  factory ClientModel.fromRecord(RecordModel r) => ClientModel(
    id: r.id,
    nom: r.getStringValue('nom'),
    telephone: r.data['telephone'] as String?,
  );
}

class MesureModel {
  final String? id; // null si pas encore de fiche enregistrée
  final String clientId;
  final double? tourPoitrine;
  final double? tourTaille;
  final double? tourBassin;
  final double? longueurRobe;
  final double? longueurManche;
  final double? tourBras;

  MesureModel({
    this.id,
    required this.clientId,
    this.tourPoitrine,
    this.tourTaille,
    this.tourBassin,
    this.longueurRobe,
    this.longueurManche,
    this.tourBras,
  });

  factory MesureModel.fromMap(Map<String, dynamic> m) => MesureModel(
    clientId: m['client_id'] as String,
    tourPoitrine: (m['tour_poitrine'] as num?)?.toDouble(),
    tourTaille: (m['tour_taille'] as num?)?.toDouble(),
    tourBassin: (m['tour_bassin'] as num?)?.toDouble(),
    longueurRobe: (m['longueur_robe'] as num?)?.toDouble(),
    longueurManche: (m['longueur_manche'] as num?)?.toDouble(),
    tourBras: (m['tour_bras'] as num?)?.toDouble(),
  );

  factory MesureModel.fromRecord(RecordModel r) => MesureModel(
    id: r.id,
    clientId: r.getStringValue('client'),
    tourPoitrine: (r.data['tour_poitrine'] as num?)?.toDouble(),
    tourTaille: (r.data['tour_taille'] as num?)?.toDouble(),
    tourBassin: (r.data['tour_bassin'] as num?)?.toDouble(),
    longueurRobe: (r.data['longueur_robe'] as num?)?.toDouble(),
    longueurManche: (r.data['longueur_manche'] as num?)?.toDouble(),
    tourBras: (r.data['tour_bras'] as num?)?.toDouble(),
  );

  /// Représentation en liste (label, valeur) pour affichage type "mètre-ruban".
  List<(String, double?)> get lignes => [
    ('Tour de poitrine', tourPoitrine),
    ('Tour de taille', tourTaille),
    ('Tour de bassin', tourBassin),
    ('Longueur robe', longueurRobe),
    ('Longueur manche', longueurManche),
    ('Tour de bras', tourBras),
  ];
}

class CommandeModel {
  final String id;
  final String clientId;
  final String clientNom;
  final String typeVetement;
  final String? tissu;
  final double prixTotal;
  final String statut; // attente | en_cours | pret | livre
  final DateTime? dateLivraisonPrevue;
  final double montantPaye;

  CommandeModel({
    required this.id,
    required this.clientId,
    required this.clientNom,
    required this.typeVetement,
    this.tissu,
    required this.prixTotal,
    required this.statut,
    this.dateLivraisonPrevue,
    this.montantPaye = 0,
  });

  double get soldeDu => prixTotal - montantPaye;
  double get progression =>
      prixTotal == 0 ? 0 : (montantPaye / prixTotal).clamp(0, 1);

  factory CommandeModel.fromMap(Map<String, dynamic> m) => CommandeModel(
    id: m['id'] as String,
    clientId: m['client_id'] as String,
    clientNom: (m['clients']?['nom'] as String?) ?? '—',
    typeVetement: m['type_vetement'] as String,
    tissu: m['tissu'] as String?,
    prixTotal: (m['prix_total'] as num).toDouble(),
    statut: m['statut'] as String,
    dateLivraisonPrevue: m['date_livraison_prevue'] != null
        ? DateTime.parse(m['date_livraison_prevue'] as String)
        : null,
    montantPaye: (m['montant_paye'] as num?)?.toDouble() ?? 0,
  );

  /// [montantPaye] n'est pas stocké sur "commandes" côté PocketBase (comme sur
  /// Supabase) — il faut le calculer séparément en sommant les "paiements"
  /// liés, puis le passer ici.
  factory CommandeModel.fromRecord(RecordModel r, {double montantPaye = 0}) {
    final clientExpand = r.expand['client']?.firstOrNull;
    return CommandeModel(
      id: r.id,
      clientId: r.getStringValue('client'),
      clientNom: clientExpand?.getStringValue('nom') ?? '—',
      typeVetement: r.getStringValue('type_vetement'),
      tissu: r.data['tissu'] as String?,
      prixTotal: (r.data['prix_total'] as num).toDouble(),
      statut: r.getStringValue('statut'),
      dateLivraisonPrevue:
          (r.data['date_livraison_prevue'] as String?)?.isNotEmpty == true
          ? DateTime.parse(r.data['date_livraison_prevue'] as String)
          : null,
      montantPaye: montantPaye,
    );
  }
}

class PaiementModel {
  final String id;
  final double montant;
  final String mode; // tmoney | flooz | moov | especes
  final DateTime createdAt;

  PaiementModel({
    required this.id,
    required this.montant,
    required this.mode,
    required this.createdAt,
  });

  factory PaiementModel.fromMap(Map<String, dynamic> m) => PaiementModel(
    id: m['id'] as String,
    montant: (m['montant'] as num).toDouble(),
    mode: m['mode'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
  factory PaiementModel.fromRecord(RecordModel r) => PaiementModel(
    id: r.id,
    montant: (r.data['montant'] as num).toDouble(),
    mode: r.getStringValue('mode'),
    createdAt: DateTime.parse(r.getStringValue('created')),
  );
  String get modeLabel => switch (mode) {
    'tmoney' => 'T-Money',
    'flooz' => 'Flooz',
    'moov' => 'Moov Money',
    _ => 'Espèces',
  };
}
