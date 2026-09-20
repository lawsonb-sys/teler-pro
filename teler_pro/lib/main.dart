import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/authgate.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/repo/offline_repo.dart';
import 'services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await initPocketBase();

  // Un dépôt par collection ayant besoin d'accès hors-ligne. Créés ici pour
  // qu'ils soient synchronisés globalement au retour de connexion — les
  // contrôleurs (ClientsController, etc.) en créent leur propre instance
  // pour lire/écrire, mais la synchronisation se fait de façon centralisée.
  final depotsASynchroniser = [
    OfflineRepository('clients'),
    OfflineRepository('mesures'),
    OfflineRepository('commandes'),
    OfflineRepository('paiments'),
    // Ajoute ici 'commandes', 'paiements', etc. au fur et à mesure
    // qu'ils adoptent aussi ce système hors-ligne.
  ];

  connectivityService.onChangement.listen((connecte) {
    if (connecte) {
      for (final depot in depotsASynchroniser) {
        depot.synchroniser();
      }
    }
  });

  runApp(ProviderScope(child: const KuturaApp()));
}

class KuturaApp extends StatelessWidget {
  const KuturaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teler pro',
      debugShowCheckedModeBanner: false,
      theme: buildKuturaTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr')],
      locale: const Locale('fr'),
      home: const AuthGate(),
    );
  }
}
