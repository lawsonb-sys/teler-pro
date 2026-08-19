import 'package:flutter/material.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/models/pocketbase.dart';
import 'package:teler_pro/outils/themes.dart';

class MesuresFormPage extends StatefulWidget {
  final String clientId;
  final MesureModel? mesureExistante; // null = première saisie

  const MesuresFormPage({
    super.key,
    required this.clientId,
    this.mesureExistante,
  });

  @override
  State<MesuresFormPage> createState() => _MesuresFormPageState();
}

class _MesuresFormPageState extends State<MesuresFormPage> {
  late final Map<String, TextEditingController> _ctrls;
  bool _envoiEnCours = false;
  String? _erreur;

  final _champs = const [
    ('tour_poitrine', 'Tour de poitrine'),
    ('tour_taille', 'Tour de taille'),
    ('tour_bassin', 'Tour de bassin'),
    ('longueur_robe', 'Longueur robe'),
    ('longueur_manche', 'Longueur manche'),
    ('tour_bras', 'Tour de bras'),
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.mesureExistante;
    _ctrls = {
      'tour_poitrine': TextEditingController(
        text: m?.tourPoitrine?.toStringAsFixed(0) ?? '',
      ),
      'tour_taille': TextEditingController(
        text: m?.tourTaille?.toStringAsFixed(0) ?? '',
      ),
      'tour_bassin': TextEditingController(
        text: m?.tourBassin?.toStringAsFixed(0) ?? '',
      ),
      'longueur_robe': TextEditingController(
        text: m?.longueurRobe?.toStringAsFixed(0) ?? '',
      ),
      'longueur_manche': TextEditingController(
        text: m?.longueurManche?.toStringAsFixed(0) ?? '',
      ),
      'tour_bras': TextEditingController(
        text: m?.tourBras?.toStringAsFixed(0) ?? '',
      ),
    };
  }

  Future<void> _enregistrer() async {
    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });

    final body = {
      for (final entry in _ctrls.entries)
        entry.key: entry.value.text.trim().isEmpty
            ? null
            : double.tryParse(entry.value.text.trim()),
      'client': widget.clientId,
    };

    try {
      if (widget.mesureExistante?.id != null) {
        // Fiche déjà existante : on met à jour.
        await pb
            .collection('mesures')
            .update(widget.mesureExistante!.id!, body: body);
      } else {
        // Première saisie pour ce client : on crée la fiche.
        await pb.collection('mesures').create(body: body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _erreur = 'Une erreur est survenue : $e');
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mesureExistante == null
              ? 'Ajouter les mesures'
              : 'Modifier les mesures',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final champ in _champs) ...[
            TextField(
              controller: _ctrls[champ.$1],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: '${champ.$2} (cm)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: KColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: KColors.cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_erreur != null) ...[
            Text(
              _erreur!,
              style: const TextStyle(color: KColors.terracotta, fontSize: 12),
            ),
            const SizedBox(height: 10),
          ],
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
    );
  }
}
