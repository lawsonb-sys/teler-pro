/// Chaque type de vêtement a son propre jeu de points de mesure.
/// Ajouter un nouveau type ou un nouveau champ se fait ICI uniquement —
/// aucune migration backend nécessaire, puisque les valeurs sont stockées
/// dans le champ souple "mesures_additionnelles" (JSON) de PocketBase.
class MesureTemplates {
  static const Map<String, List<(String cle, String label)>> parType = {
    'chemise': [
      ('tour_cou', 'Tour de cou'),
      ('tour_poitrine', 'Tour de poitrine'),
      ('tour_taille', 'Tour de taille'),
      ('longueur_chemise', 'Longueur chemise'),
      ('longueur_manche', 'Longueur manche'),
      ('tour_epaule', 'Tour d\'épaule'),
      ('tour_poignet', 'Tour de poignet'),
    ],
    'robe': [
      ('tour_poitrine', 'Tour de poitrine'),
      ('tour_taille', 'Tour de taille'),
      ('tour_bassin', 'Tour de bassin'),
      ('longueur_robe', 'Longueur robe'),
      ('longueur_manche', 'Longueur manche'),
      ('tour_bras', 'Tour de bras'),
    ],
    'costume': [
      ('tour_poitrine', 'Tour de poitrine'),
      ('tour_taille', 'Tour de taille'),
      ('longueur_veste', 'Longueur veste'),
      ('longueur_manche', 'Longueur manche'),
      ('tour_epaule', 'Tour d\'épaule'),
      ('longueur_pantalon', 'Longueur pantalon'),
      ('tour_cuisse', 'Tour de cuisse'),
    ],
    'boubou': [
      ('tour_poitrine', 'Tour de poitrine'),
      ('longueur_boubou', 'Longueur boubou'),
      ('tour_epaule', 'Tour d\'épaule'),
      ('longueur_manche', 'Longueur manche'),
    ],
    // 'autre' n'a pas de gabarit fixe : voir MesuresFormPage, qui laisse
    // le tailleur nommer lui-même ses points de mesure pour ce cas.
  };

  static const Map<String, String> labelType = {
    'chemise': 'Chemise',
    'robe': 'Robe',
    'costume': 'Costume',
    'boubou': 'Boubou',
    'autre': 'Autre',
  };

  /// Renvoie une liste vide pour 'autre' — ce type n'a pas de gabarit fixe,
  /// voir MesuresFormPage pour la saisie de champs libres.
  static List<(String, String)> champsPour(String typeVetement) =>
      parType[typeVetement] ?? [];
}
