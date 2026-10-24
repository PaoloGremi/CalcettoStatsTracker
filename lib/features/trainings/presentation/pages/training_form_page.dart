import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/util/date_formatters.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/training.dart';
import '../controllers/trainings_controller.dart';
import '../training_format.dart';
import '../widgets/training_list_tile.dart'
    show trainingTypeColor, trainingTypeIcon;

/// Crea o modifica un allenamento. Legge [TrainingsController] dal Provider.
/// Torna `true` al chiamante se ha salvato o eliminato.
class TrainingFormPage extends StatefulWidget {
  const TrainingFormPage({super.key, this.initial});

  final Training? initial;

  @override
  State<TrainingFormPage> createState() => _TrainingFormPageState();
}

class _TrainingFormPageState extends State<TrainingFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final String _id;
  late DateTime _date;
  late TrainingType _type;
  late Set<TechnicalCategory> _categories;
  late final TextEditingController _runTime;
  late final TextEditingController _distance;
  late final TextEditingController _duration;
  late final TextEditingController _notes;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    final now = DateTime.now();
    _id = t?.id ?? const Uuid().v4();
    _date = t?.date ?? DateTime(now.year, now.month, now.day);
    _type = t?.type ?? TrainingType.running;
    _categories = {...?t?.categories};
    _runTime = TextEditingController(
        text: t?.runSeconds != null ? formatRunTime(t!.runSeconds!) : '');
    _distance = TextEditingController(
        text: t?.distanceKm != null ? formatKm(t!.distanceKm!) : '');
    _duration =
        TextEditingController(text: t?.durationMinutes?.toString() ?? '');
    _notes = TextEditingController(text: t?.notes ?? '');
  }

  @override
  void dispose() {
    _runTime.dispose();
    _distance.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final training = Training(
      id: _id,
      date: _date,
      type: _type,
      durationMinutes: int.tryParse(_duration.text.trim()),
      distanceKm: parseKm(_distance.text),
      runSeconds: parseRunTime(_runTime.text),
      categories: _categories,
      notes: _notes.text,
    );
    setState(() => _saving = true);
    final message = await context.read<TrainingsController>().save(training);
    if (!mounted) return;
    setState(() => _saving = false);
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    Navigator.of(context).maybePop(true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare questo allenamento?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Elimina', style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<TrainingsController>().remove(_id);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).maybePop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossibile eliminare l\'allenamento')));
    }
  }

  String? _validateRunTime(String? v) =>
      parseRunTime(v ?? '') == null ? 'Formato tempo non valido' : null;

  String? _validateDistance(String? v) =>
      parseKm(v ?? '') == null ? 'Distanza non valida' : null;

  String? _validateDuration(String? v) {
    final n = int.tryParse((v ?? '').trim());
    return (n == null || n <= 0) ? 'Durata non valida' : null;
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifica allenamento' : 'Nuovo allenamento'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Elimina',
              icon: Icon(Icons.delete_outline_rounded,
                  color: AppTheme.accentRed),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Chip che vanno a capo: con cinque tipi una barra a segmenti
            // non starebbe su uno schermo stretto.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in TrainingType.values)
                  ChoiceChip(
                    avatar: Icon(trainingTypeIcon(t),
                        size: 18, color: trainingTypeColor(t)),
                    label: Text(t.label),
                    selected: _type == t,
                    showCheckmark: false,
                    selectedColor:
                        trainingTypeColor(t).withValues(alpha: 0.25),
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.event_rounded, color: AppTheme.accentGreen),
              title: Text(formatDayMonthYear(_date),
                  style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text('Data',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              onTap: _pickDate,
            ),
            if (_type.hasDistance) ...[
              _sectionTitle(
                  _type == TrainingType.walking ? 'Camminata' : 'Corsa'),
              TextFormField(
                key: const Key('distance_field'),
                controller: _distance,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Distanza (km)', hintText: 'es. 5,2'),
                validator: _validateDistance,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('run_time_field'),
                controller: _runTime,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                    labelText: _type == TrainingType.walking
                        ? 'Tempo'
                        : 'Tempo di corsa',
                    hintText: 'mm:ss o h:mm:ss'),
                validator: _validateRunTime,
              ),
            ],
            if (_type.hasDuration) ...[
              _sectionTitle(
                  _type.hasTechnical ? 'Parte tecnica' : _type.label),
              TextFormField(
                key: const Key('duration_field'),
                controller: _duration,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Durata (minuti)'),
                validator: _validateDuration,
              ),
            ],
            if (_type.hasTechnical) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in TechnicalCategory.values)
                    FilterChip(
                      label: Text(c.label),
                      selected: _categories.contains(c),
                      selectedColor:
                          AppTheme.accentGreen.withValues(alpha: 0.25),
                      onSelected: (on) => setState(() =>
                          on ? _categories.add(c) : _categories.remove(c)),
                    ),
                ],
              ),
            ],
            _sectionTitle('Note'),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(hintText: 'Facoltative'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('save_button'),
              onPressed: _saving ? null : _save,
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
