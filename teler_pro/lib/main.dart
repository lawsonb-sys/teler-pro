import 'package:flutter/material.dart';
import 'package:teler_pro/outils/authgate.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ données embarquées dans le code, pas de lecture fichier
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
