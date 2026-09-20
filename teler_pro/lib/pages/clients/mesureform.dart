import 'package:flutter/material.dart';
import 'package:teler_pro/models/model.dart';
import 'package:teler_pro/outils/mesure_template.dart';
import 'package:teler_pro/outils/themes.dart';
import 'package:teler_pro/repo/offline_repo.dart';

/// Une paire (nom du champ, valeur) pour le type "Autre", où le tailleur
/// choisit lui-même ses points de mesure plutôt qu'un gabarit fixe.
class _ChampLibre {
  final TextEditingController labelCtrl;
  final TextEditingController valeurCtrl;
  _ChampLibre({String label = '', String valeur = ''})
    : labelCtrl = TextEditingController(text: label),
      valeurCtrl = TextEditingController(text: valeur);

  void dispose() {
    labelCtrl.dispose();
    valeurCtrl.dispose();
  }
}

class MesuresFormPage extends StatefulWidget {
  final String clientId;
  final MesureModel? mesureExistante;
  final String? typeVetementInitial;
  final OfflineRepository mesuresRepo;

  const MesuresFormPage({
    super.key,
    required this.clientId,
    required this.mesuresRepo,
    this.mesureExistante,
    this.typeVetementInitial,
  });

  @override
  State<MesuresFormPage> createState() => _MesuresFormPageState();
}

class _MesuresFormPageState extends State<MesuresFormPage> {
  late String _typeVetement;
  Map<String, TextEditingController> _ctrls =
      {}; // pour les types à gabarit fixe
  List<_ChampLibre> _champsLibres = []; // pour le type "autre"
  bool _envoiEnCours = false;
  String? _erreur;

  bool get _estAutre => _typeVetement == 'autre';

  @override
  void initState() {
    super.initState();
    _typeVetement =
        widget.mesureExistante?.typeVetement ??
        widget.typeVetementInitial ??
        'robe';
    _initChamps();
  }

  void _initChamps() {
    // On nettoie les anciens contrôleurs avant d'en recréer, pour éviter les fuites mémoire.
    for (final c in _ctrls.values) {
      c.dispose();
    }
    for (final c in _champsLibres) {
      c.dispose();
    }

    if (_estAutre) {
      final valeursExistantes = widget.mesureExistante?.valeurs ?? {};
      _champsLibres = valeursExistantes.isEmpty
          ? [_ChampLibre()] // une ligne vide par défaut pour commencer à saisir
          : valeursExistantes.entries
                .map(
                  (e) => _ChampLibre(
                    label: e.key,
                    valeur: e.value.toStringAsFixed(0),
                  ),
                )
                .toList();
      _ctrls = {};
    } else {
      final champs = MesureTemplates.champsPour(_typeVetement);
      final valeursExistantes = widget.mesureExistante?.valeurs ?? {};
      _ctrls = {
        for (final champ in champs)
          champ.$1: TextEditingController(
            text: valeursExistantes[champ.$1]?.toStringAsFixed(0) ?? '',
          ),
      };
      _champsLibres = [];
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    for (final c in _champsLibres) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enregistrer() async {
    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });

    final valeurs = <String, double>{};

    if (_estAutre) {
      for (final champ in _champsLibres) {
        final label = champ.labelCtrl.text.trim();
        final texte = champ.valeurCtrl.text.trim();
        if (label.isNotEmpty && texte.isNotEmpty) {
          final v = double.tryParse(texte);
          if (v != null) valeurs[label] = v;
        }
      }
      if (valeurs.isEmpty) {
        setState(() {
          _erreur =
              'Ajoute au moins un point de mesure avec un nom et une valeur';
          _envoiEnCours = false;
        });
        return;
      }
    } else {
      for (final entry in _ctrls.entries) {
        final texte = entry.value.text.trim();
        if (texte.isNotEmpty) {
          final v = double.tryParse(texte);
          if (v != null) valeurs[entry.key] = v;
        }
      }
    }

    final body = {
      'client': widget.clientId,
      'type_vetement': _typeVetement,
      'mesures_additionnelles': valeurs,
    };

    try {
      if (widget.mesureExistante?.id != null) {
        await widget.mesuresRepo.modifier(widget.mesureExistante!.id!, body);
      } else {
        await widget.mesuresRepo.creer(body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _erreur = 'Une erreur est survenue : $e');
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  InputDecoration _decoration({String? label}) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
    final champs = MesureTemplates.champsPour(_typeVetement);
    final typeModifiable = widget.mesureExistante == null;

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
          if (typeModifiable) ...[
            Text(
              'TYPE DE VÊTEMENT',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                color: KColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _typeVetement,
              decoration: _decoration(),
              items: MesureTemplates.labelType.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _typeVetement = v;
                  _initChamps();
                });
              },
            ),
            const SizedBox(height: 20),
          ] else ...[
            Text(
              'Mesures — ${MesureTemplates.labelType[_typeVetement]}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KColors.indigo,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_estAutre) ...[
            Text(
              'POINTS DE MESURE PERSONNALISÉS',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                color: KColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < _champsLibres.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _champsLibres[i].labelCtrl,
                      decoration: _decoration(
                        label: 'Nom (ex. Tour de mollet)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _champsLibres[i].valeurCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _decoration(label: 'cm'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: KColors.muted, size: 18),
                    onPressed: _champsLibres.length == 1
                        ? null // toujours garder au moins une ligne visible
                        : () => setState(() {
                            _champsLibres[i].dispose();
                            _champsLibres.removeAt(i);
                          }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            TextButton.icon(
              onPressed: () => setState(() => _champsLibres.add(_ChampLibre())),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter un point de mesure'),
            ),
            const SizedBox(height: 12),
          ] else
            for (final champ in champs) ...[
              TextField(
                controller: _ctrls[champ.$1],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration(label: '${champ.$2} (cm)'),
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
