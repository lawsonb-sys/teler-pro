import 'package:flutter/material.dart';
import 'package:teler_pro/controlers/client_ctr.dart';
import 'package:teler_pro/outils/atelier_serevice.dart';
import 'package:teler_pro/outils/themes.dart';

class NouveauClientPage extends StatefulWidget {
  final ClientsController controller;
  const NouveauClientPage({super.key, required this.controller});

  @override
  State<NouveauClientPage> createState() => _NouveauClientPageState();
}

class _NouveauClientPageState extends State<NouveauClientPage> {
  final _nomCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _envoiEnCours = false;
  String? _erreur;

  Future<void> _enregistrer() async {
    if (_nomCtrl.text.trim().isEmpty) {
      setState(() => _erreur = 'Le nom est obligatoire');
      return;
    }

    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });

    try {
      final atelier = await atelierService.atelierCourant();
      await widget.controller.ajouter({
        'atelier': atelier.id,
        'nom': _nomCtrl.text.trim(),
        'telephone': _telephoneCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _erreur = 'Une erreur est survenue : $e');
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: KColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: KColors.cardBorder),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau client')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nomCtrl, decoration: _decoration('Nom')),
            const SizedBox(height: 12),
            TextField(
              controller: _telephoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _decoration('Téléphone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: _decoration('Notes (optionnel)'),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 10),
              Text(
                _erreur!,
                style: const TextStyle(color: KColors.terracotta, fontSize: 12),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _envoiEnCours ? null : _enregistrer,
              child: _envoiEnCours
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
