import 'package:pocketbase/pocketbase.dart';
import 'package:teler_pro/outils/mesure_template.dart';

class ClientModel {
  final String id;
  final String nom;
  final String? telephone;
  final bool
  enAttente; // true si créé hors-ligne, pas encore synchronisé avec le serveur

  ClientModel({
    required this.id,
    required this.nom,
    this.telephone,
    this.enAttente = false,
  });

  factory ClientModel.fromMap(Map<String, dynamic> m) => ClientModel(
    id: m['id'] as String,
    nom: m['nom'] as String,
    telephone: m['telephone'] as String?,
  );

  factory ClientModel.fromRecord(RecordModel r) => ClientModel(
    id: r.id,
    nom: r.getStringValue('nom'),
    telephone: r.data['telephone'] as String?,
    // Un enregistrement lu directement depuis PocketBase est par
    // définition déjà synchronisé.
    enAttente: false,
  );

  /// Depuis une map brute stockée dans le cache Hive (voir OfflineRepository) —
  /// mêmes noms de champs que PocketBase, puisqu'on stocke r.data tel quel.
  factory ClientModel.fromCacheMap(Map<String, dynamic> m) => ClientModel(
    id: m['id'] as String,
    nom: m['nom'] as String? ?? '',
    telephone: m['telephone'] as String?,
    enAttente: m['en_attente'] as bool? ?? false,
  );
}

class MesureModel {
  final String? id; // null si pas encore de fiche enregistrée
  final String clientId;
  final String
  typeVetement; // 'chemise' | 'robe' | 'costume' | 'boubou' | 'autre'
  final Map<String, double> valeurs; // clé technique -> valeur en cm
  final bool
  enAttente; // true si créé/modifié hors-ligne, pas encore synchronisé

  MesureModel({
    this.id,
    required this.clientId,
    required this.typeVetement,
    required this.valeurs,
    this.enAttente = false,
  });

  factory MesureModel.fromRecord(RecordModel r) {
    final brut =
        r.data['mesures_additionnelles'] as Map<String, dynamic>? ?? {};
    return MesureModel(
      id: r.id,
      clientId: r.getStringValue('client'),
      typeVetement: r.getStringValue('type_vetement'),
      valeurs: brut.map(
        (cle, valeur) => MapEntry(cle, (valeur as num).toDouble()),
      ),
      enAttente: false, // vient directement du serveur : forcément synchronisé
    );
  }

  /// Depuis une map brute du cache Hive (voir OfflineRepository).
  factory MesureModel.fromCacheMap(Map<String, dynamic> m) {
    final brut = m['mesures_additionnelles'] as Map? ?? {};
    return MesureModel(
      id: m['id'] as String?,
      clientId: m['client'] as String? ?? '',
      typeVetement: m['type_vetement'] as String? ?? 'autre',
      valeurs: brut.map(
        (cle, valeur) => MapEntry(cle as String, (valeur as num).toDouble()),
      ),
      enAttente: m['en_attente'] as bool? ?? false,
    );
  }

  /// Représentation en liste (label, valeur) pour affichage type "mètre-ruban",
  /// dans l'ordre défini par le gabarit de ce type de vêtement — sauf pour
  /// 'autre', qui n'a pas de gabarit fixe : on affiche directement les
  /// champs libres tels que le tailleur les a nommés.
  List<(String, double?)> get lignes {
    if (typeVetement == 'autre') {
      return valeurs.entries.map((e) => (e.key, e.value)).toList();
    }
    final champs = MesureTemplates.champsPour(typeVetement);
    return champs.map((champ) {
      final (cle, label) = champ;
      return (label, valeurs[cle]);
    }).toList();
  }
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
  final bool enAttente;

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
    this.enAttente = false,
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
      enAttente: false,
    );
  }

  /// Méthode pour copier et modifier un champ (statut, montantPaye, etc.)
  CommandeModel copyWith({
    String? id,
    String? clientId,
    String? clientNom,
    String? typeVetement,
    String? tissu,
    double? prixTotal,
    String? statut,
    DateTime? dateLivraisonPrevue,
    double? montantPaye,
    bool? enAttente,
  }) {
    return CommandeModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientNom: clientNom ?? this.clientNom,
      typeVetement: typeVetement ?? this.typeVetement,
      tissu: tissu ?? this.tissu,
      prixTotal: prixTotal ?? this.prixTotal,
      statut: statut ?? this.statut,
      dateLivraisonPrevue: dateLivraisonPrevue ?? this.dateLivraisonPrevue,
      montantPaye: montantPaye ?? this.montantPaye,
      enAttente: enAttente ?? this.enAttente,
    );
  }

  /// Depuis une map brute du cache Hive. Le nom du client doit avoir été
  /// ajouté au cache via le paramètre "enrichir" de OfflineRepository.actualiser()
  /// (voir CommandesController), sinon on retombe sur son ID.
  factory CommandeModel.fromCacheMap(
    Map<String, dynamic> m, {
    double montantPaye = 0,
  }) {
    return CommandeModel(
      id: m['id'] as String? ?? '',
      clientId: m['client'] as String? ?? '',
      // 1. On cherche 'clientNom' (injecté par le controller) PUIS 'client_nom' PUIS 'nom'
      clientNom:
          m['clientNom'] as String? ??
          m['client_nom'] as String? ??
          m['nom'] as String? ??
          '—',
      typeVetement:
          m['type_vetement'] as String? ?? m['typeVetement'] as String? ?? '',
      tissu: m['tissu'] as String?,
      prixTotal: (m['prix_total'] ?? m['prixTotal'] as num?)?.toDouble() ?? 0,
      // 2. On s'assure de nettoyer le statut pour éviter tout mismatch de casse
      statut: (m['statut'] as String? ?? 'attente').trim().toLowerCase(),
      dateLivraisonPrevue:
          (m['date_livraison_prevue'] as String?)?.isNotEmpty == true
          ? DateTime.tryParse(m['date_livraison_prevue'] as String)
          : null,
      montantPaye: montantPaye,
      enAttente: m['en_attente'] as bool? ?? false,
    );
  }
}

class PaiementModel {
  final String id;
  final String commandeId;
  final double montant;
  final String mode; // tmoney | flooz | moov | especes
  final DateTime createdAt;
  final bool enAttente;

  PaiementModel({
    required this.id,
    required this.commandeId,
    required this.montant,
    required this.mode,
    required this.createdAt,
    this.enAttente = false,
  });

  factory PaiementModel.fromMap(Map<String, dynamic> m) => PaiementModel(
    id: m['id'] as String,
    commandeId: m['commande_id'] as String? ?? '',
    montant: (m['montant'] as num).toDouble(),
    mode: m['mode'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
  );

  factory PaiementModel.fromRecord(RecordModel r) => PaiementModel(
    id: r.id,
    commandeId: r.getStringValue('commande'),
    montant: (r.data['montant'] as num).toDouble(),
    mode: r.getStringValue('mode'),
    createdAt: DateTime.parse(r.getStringValue('created')),
    enAttente: false,
  );

  /// Depuis une map brute du cache Hive. Pas de vraie date "created" tant
  /// que ce n'est pas encore synchronisé : on utilise "maintenant" comme
  /// approximation raisonnable pour l'affichage.
  factory PaiementModel.fromCacheMap(Map<String, dynamic> m) => PaiementModel(
    id: m['id'] as String,
    commandeId: m['commande'] as String? ?? '',
    montant: (m['montant'] as num?)?.toDouble() ?? 0,
    mode: m['mode'] as String? ?? 'especes',
    createdAt: m['created'] != null
        ? DateTime.parse(m['created'] as String)
        : DateTime.now(),
    enAttente: m['en_attente'] as bool? ?? false,
  );

  String get modeLabel => switch (mode) {
    'tmoney' => 'T-Money',
    'flooz' => 'Flooz',
    'moov' => 'Moov Money',
    _ => 'Espèces',
  };
}
