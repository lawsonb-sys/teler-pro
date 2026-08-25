import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teler_pro/outils/bottomnav.dart';
import 'package:teler_pro/pages/accueil.dart';
import 'package:teler_pro/pages/clients/clientpages.dart';
import 'package:teler_pro/pages/commandes/commandes.dart';
import 'package:teler_pro/pages/profile.dart';

/// Point d'entrée après connexion : gère les 4 onglets principaux.
/// Les écrans de détail (fiche client, nouvelle commande, paiement)
/// se poussent PAR-DESSUS ce shell avec Navigator.push — ils ne sont pas
/// des onglets, donc ils sortent naturellement de l'IndexedStack.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // Un seul exemplaire de chaque page, jamais recréé : IndexedStack les garde
  // toutes en mémoire et bascule juste laquelle est visible → le scroll,
  // les filtres sélectionnés etc. sont conservés quand on revient sur un onglet.
  final _pages = const [
    AccueilPage(),
    ClientsPage(),
    CommandesPage(),
    ProfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(
          top: true,
          bottom: false,
          child: IndexedStack(index: _index, children: _pages),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: KuturaBottomNav(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
          ),
        ),
      ),
    );
  }
}
