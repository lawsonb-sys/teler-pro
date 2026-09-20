// Créez simplement cette variable globale (dans un fichier commande_provider.dart)
import 'package:flutter_riverpod/legacy.dart';
import 'package:teler_pro/controlers/commande_ctr.dart';

final commandesControllerProvider = ChangeNotifierProvider<CommandesController>(
  (ref) {
    return CommandesController();
  },
);
