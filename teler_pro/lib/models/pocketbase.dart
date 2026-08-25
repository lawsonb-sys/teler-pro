import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instance unique de PocketBase, partagée dans toute l'app.
/// `late` : elle est déclarée ici mais initialisée seulement au démarrage,
/// via initPocketBase() — voir main.dart.
late final PocketBase pb;

/// À appeler UNE FOIS, avant runApp(), pour que la session (le token de
/// connexion) survive à la fermeture complète de l'app — sans jamais
/// stocker le mot de passe lui-même, seulement le token déjà obtenu.
Future<void> initPocketBase() async {
  final prefs = await SharedPreferences.getInstance();

  final store = AsyncAuthStore(
    save: (String data) async => prefs.setString('pb_auth', data),
    initial: prefs.getString(
      'pb_auth',
    ), // relit la session sauvegardée au démarrage
    clear: () async =>
        prefs.remove('pb_auth'), // appelé automatiquement à la déconnexion
  );

  // URL à adapter selon où tourne le serveur :
  // - Émulateur Android : http://10.0.2.2:8090
  // - iOS Simulator / Chrome / Windows desktop : http://127.0.0.1:8090
  // - Téléphone physique sur le même Wi-Fi : http://<IP-locale-de-ton-PC>:8090
  pb = PocketBase('http://192.168.1.68:8090', authStore: store);
}
