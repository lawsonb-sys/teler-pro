import 'package:flutter/material.dart';
import 'package:teler_pro/outils/themes.dart';

/// Barre de navigation du bas, avec la graduation "mètre-ruban" en haut
/// (crans clairs/foncés répétés) — reprend le motif ::before du tabbar
/// dans la maquette HTML.
class KuturaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const KuturaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _tabs = [
    ('Accueil', Icons.home_outlined),
    ('Clients', Icons.people_outline),
    ('Commandes', Icons.receipt_long_outlined),
    ('Profil', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: KColors.cardBorder)),
      ),
      child: Column(
        children: [
          // Le ruban de graduation, collé au bord supérieur de la barre.
          const _TapeTicks(),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final (label, icon) = _tabs[i];
                final actif = currentIndex == i;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Le petit point orange au-dessus du libellé actif,
                      // comme la ".dot" de la maquette.
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: actif
                              ? KColors.terracotta
                              : Colors.transparent,
                        ),
                      ),
                      Icon(
                        icon,
                        size: 18,
                        color: actif ? KColors.indigo : const Color(0xFFB3AA98),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          color: actif
                              ? KColors.indigo
                              : const Color(0xFFB3AA98),
                          fontWeight: actif
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dessine la fine bande de graduation (crans courts/longs) en haut de la tabbar.
class _TapeTicks extends StatelessWidget {
  const _TapeTicks();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      width: double.infinity,
      child: CustomPaint(painter: _TickPainter()),
    );
  }
}

class _TickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = KColors.brass
      ..strokeWidth = 1;

    const step = 8.0; // espace entre deux crans
    const inset = 14.0; // marge gauche/droite, comme le padding de la maquette
    var x = inset;
    while (x < size.width - inset) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += step;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
