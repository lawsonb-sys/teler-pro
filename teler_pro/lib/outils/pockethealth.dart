import 'package:pocketbase/pocketbase.dart';

extension PocketBaseHealth on PocketBase {
  /// Vérifie si le serveur PocketBase est réellement accessible
  Future<bool> estServeurAccessible() async {
    try {
      // Renommage de la variable locale pour éviter le conflit de nom avec this.health
      final response = await health.check().timeout(const Duration(seconds: 3));

      // Verification du statut HTTP 200
      return response.code == 200;
    } catch (_) {
      // Retourne false en cas de Timeout, SocketException ou serveur indisponible
      return false;
    }
  }
}