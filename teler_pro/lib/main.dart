import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/authgate.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ données embarquées dans le code, pas de lecture fichier
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:teler_pro/repo/offline_repo.dart';
import 'package:teler_pro/services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await Hive.initFlutter();
  await initPocketBase();

  // Un dépôt par collection ayant besoin d'accès hors-ligne. Créés ici pour
  // qu'ils soient synchronisés globalement au retour de connexion — les
  // contrôleurs (ClientsController, etc.) en créent leur propre instance
  // pour lire/écrire, mais la synchronisation se fait de façon centralisée.
  final depotsASynchroniser = [
    OfflineRepository('clients'),
    // Ajoute ici 'commandes', 'paiements', etc. au fur et à mesure
    // qu'ils adoptent aussi ce système hors-ligne.
  ];

  connectivityService.onChangement.listen((connecte) {
    if (connecte) {
      for (final depot in depotsASynchroniser) {
        depot.synchroniser();
      }
    }
  }); // Initialiser PocketBase avant de lancer l'application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Teler Pro',
      theme: buildKuturaTheme(),
      home: const AuthGate(),
    );
  }
}
