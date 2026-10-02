// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';

import 'package:teler_pro/main.dart';
import 'package:teler_pro/models/pocketbase.dart';

void main() {
  // 1. Initialiser PocketBase avant l'exécution des tests
  setUp(() {
    pb = PocketBase('http://192.168.1.68:8090'); // Remplacez par l'URL ou un mock
  });

  testWidgets('Chargement de l\'écran d\'accueil KuturaApp', (WidgetTester tester) async {
    // 2. Charger votre application
    await tester.pumpWidget(const KuturaApp());

    // 3. Laisser le temps aux animations et futures de se terminer
    await tester.pumpAndSettle();

    // 4. Tester des éléments réellement présents dans votre interface KuturaApp
    // Exemple : Vérifier qu'un texte ou un bouton spécifique existe
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}