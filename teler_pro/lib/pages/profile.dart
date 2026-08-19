import 'package:flutter/material.dart';
import 'package:teler_pro/models/mockdata.dart';
import 'package:teler_pro/outils/themes.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: Text(
          MockData.nomAtelier,
          style: const TextStyle(fontSize: 16, color: KColors.ink),
        ),
      ),
    );
  }
}
