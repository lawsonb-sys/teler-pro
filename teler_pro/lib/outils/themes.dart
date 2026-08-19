import 'package:flutter/material.dart';

/// Palette de couleurs de Kutura, reprise de la maquette UX
/// (mètre-ruban, tissus wax, outils de couture).
class KColors {
  static const indigo = Color(0xFF1B3358);
  static const indigoDeep = Color(0xFF10233F);
  static const brass = Color(0xFFC99A3C);
  static const brassLight = Color(0xFFE4C374);
  static const ecru = Color(0xFFF3ECDD);
  static const terracotta = Color(0xFFB8562F);
  static const ink = Color(0xFF26211C);
  static const threadGreen = Color(0xFF4C6B4F);
  static const cardBorder = Color(0xFFE3D9C4);
  static const muted = Color(0xFF8A8171);
}

ThemeData buildKuturaTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: KColors.ecru,
    fontFamily: 'WorkSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: KColors.indigo,
      primary: KColors.indigo,
      secondary: KColors.terracotta,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: KColors.indigo,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: KColors.cardBorder),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: KColors.terracotta,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KColors.terracotta,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// Badge de statut réutilisé sur plusieurs écrans (Accueil, Commandes).
class StatutBadge extends StatelessWidget {
  final String statut;
  const StatutBadge({super.key, required this.statut});

  ({Color bg, Color fg, String label}) get _style => switch (statut) {
    'attente' => (
      bg: const Color(0xFFEFE1C6),
      fg: const Color(0xFF8A6A1F),
      label: 'En attente',
    ),
    'en_cours' => (
      bg: const Color(0xFFDCE6DC),
      fg: KColors.threadGreen,
      label: 'En cours',
    ),
    'pret' => (
      bg: const Color(0xFFF1DACB),
      fg: KColors.terracotta,
      label: 'Prêt',
    ),
    'livre' => (
      bg: const Color(0xFFE1E6EC),
      fg: KColors.indigo,
      label: 'Livré',
    ),
    _ => (bg: Colors.grey.shade200, fg: Colors.grey.shade700, label: statut),
  };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        s.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: s.fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
