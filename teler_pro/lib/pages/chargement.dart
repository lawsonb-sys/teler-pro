import 'package:flutter/material.dart';
import 'package:teler_pro/outils/themes.dart';

class ChargementPage extends StatelessWidget {
  const ChargementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.ecru,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Teler Pro',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: KColors.indigo,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: KColors.terracotta,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
