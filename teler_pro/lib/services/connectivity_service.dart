import 'package:connectivity_plus/connectivity_plus.dart';

/// Surveille l'état de la connexion internet du téléphone.
class ConnectivityService {
  final _connectivity = Connectivity();

  /// Vérifie l'état actuel, une seule fois.
  Future<bool> estConnecte() async {
    final resultats = await _connectivity.checkConnectivity();
    return _aUneConnexion(resultats);
  }

  /// Flux qui notifie à chaque changement (perte ou retour de connexion).
  Stream<bool> get onChangement =>
      _connectivity.onConnectivityChanged.map(_aUneConnexion);

  bool _aUneConnexion(List<ConnectivityResult> resultats) {
    // Avoir un signal Wi-Fi/données ne garantit pas un vrai accès internet
    // (ex. Wi-Fi sans internet), mais c'est suffisant pour notre usage :
    // savoir s'il vaut la peine de tenter une requête PocketBase.
    return resultats.any((r) => r != ConnectivityResult.none);
  }
}

final connectivityService = ConnectivityService();
