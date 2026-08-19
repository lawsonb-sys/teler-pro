// lib/controllers/accueil_controller.dart
import 'package:flutter/material.dart';
import 'package:teler_pro/outils/accueil_rapo.dart';

sealed class AccueilState {}

class AccueilLoading extends AccueilState {}

class AccueilSuccess extends AccueilState {
  final AccueilData data;
  AccueilSuccess(this.data);
}

class AccueilError extends AccueilState {
  final String message;
  AccueilError(this.message);
}

class AccueilController extends ValueNotifier<AccueilState> {
  final AccueilRepository _repository;

  AccueilController({AccueilRepository? repository})
    : _repository = repository ?? AccueilRepository(),
      super(AccueilLoading());

  Future<void> charger() async {
    value = AccueilLoading();
    try {
      final data = await _repository.chargers();
      value = AccueilSuccess(data);
    } catch (e) {
      // AJOUTEZ CETTE LIGNE :
      debugPrint('ERREUR DÉTAILLÉE : $e');
      value = AccueilError(e.toString());
    }
  }
}
