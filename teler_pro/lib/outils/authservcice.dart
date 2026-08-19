import 'package:pocketbase/pocketbase.dart';
import 'package:teler_pro/models/pocketbase.dart';

class AuthService {
  /// true si un utilisateur est actuellement connecté (session valide en mémoire/disque).
  bool get estConnecte => pb.authStore.isValid;

  /// Notifie l'app à chaque changement d'état de connexion (connexion, déconnexion,
  /// token expiré). Utilisé par AuthGate pour basculer Login <-> MainShell.
  void ecouterChangements(void Function() onChange) {
    pb.authStore.onChange.listen((_) => onChange());
  }

  Future<void> inscrire({
    required String email,
    required String motDePasse,
    required String nomAtelier,
  }) async {
    // 1. Créer le compte utilisateur.
    await pb
        .collection('users')
        .create(
          body: {
            'email': email,
            'password': motDePasse,
            'passwordConfirm': motDePasse,
            'nom_atelier': nomAtelier,
          },
        );
    // 2. Se connecter directement après inscription.
    // Le hook on_user_created.pb.js aura déjà créé la ligne "ateliers" à ce stade
    // (il s'exécute juste après l'étape 1, avant que ce await ne se termine).
    await pb.collection('users').authWithPassword(email, motDePasse);
  }

  Future<void> connecter({
    required String email,
    required String motDePasse,
  }) async {
    await pb.collection('users').authWithPassword(email, motDePasse);
  }

  void deconnecter() {
    pb.authStore.clear();
  }

  /// Message d'erreur lisible à partir d'une ClientException PocketBase.
  String messageErreur(Object e) {
    if (e is ClientException) {
      // PocketBase renvoie souvent le détail par champ dans e.response['data']
      final data = e.response['data'] as Map<String, dynamic>?;
      if (data != null && data.isNotEmpty) {
        final premier = data.values.first;
        if (premier is Map && premier['message'] != null) {
          return premier['message'] as String;
        }
      }
      return e.response['message'] as String? ?? 'Une erreur est survenue';
    }
    return 'Une erreur est survenue : $e';
  }
}

final authService = AuthService();
