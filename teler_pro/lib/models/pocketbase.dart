import 'package:pocketbase/pocketbase.dart';

/// Instance unique de PocketBase, partagée dans toute l'app.
///
/// URL à adapter selon où tourne le serveur :
/// - Émulateur Android : http://10.0.2.2:8090   (10.0.2.2 = ton PC vu depuis l'émulateur)
/// - iOS Simulator / Chrome / Windows desktop : http://127.0.0.1:8090
/// - Téléphone physique sur le même Wi-Fi : http://<IP-locale-de-ton-PC>:8090
/// - En production : l'URL de ton VPS (ex. https://api.kutura.app)
final pb = PocketBase('http://192.168.1.68:8090');
