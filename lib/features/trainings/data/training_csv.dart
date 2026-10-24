import 'package:intl/intl.dart';

import '../domain/entities/training.dart';
import 'models/training_model.dart';

/// Colonne di `trainings.csv`.
const trainingCsvHeader = [
  'id',
  'date',
  'type',
  'duration_min',
  'distance_km',
  'run_seconds',
  'categories',
  'notes',
];

final _date = DateFormat('dd/MM/yyyy');

/// Header + una riga per allenamento. Km con punto decimale, categorie
/// separate da `|`, valori assenti come stringa vuota.
List<List<String>> trainingsToCsvRows(List<TrainingModel> items) => [
      trainingCsvHeader,
      for (final t in items)
        [
          t.id,
          _date.format(t.date),
          t.type,
          t.durationMinutes?.toString() ?? '',
          t.distanceKm?.toString() ?? '',
          t.runSeconds?.toString() ?? '',
          t.categories.join('|'),
          t.notes ?? '',
        ],
    ];

/// Riga CSV → modello, o null se la riga non è valida (colonne mancanti,
/// id vuoto, data o tipo non riconosciuti).
TrainingModel? trainingFromCsvRow(List<dynamic> row) {
  if (row.length < trainingCsvHeader.length) return null;
  final cells = [for (final c in row) c.toString().trim()];
  final id = cells[0];
  if (id.isEmpty) return null;

  final DateTime date;
  try {
    date = _date.parseStrict(cells[1]);
  } on FormatException {
    return null;
  }

  final type = cells[2];
  if (!TrainingType.values.any((t) => t.name == type)) return null;

  final km = double.tryParse(cells[4]);
  if (km != null && !km.isFinite) return null;

  final notes = row[7].toString();
  return TrainingModel(
    id: id,
    date: date,
    type: type,
    durationMinutes: int.tryParse(cells[3]),
    distanceKm: km,
    runSeconds: int.tryParse(cells[5]),
    categories: [
      for (final c in cells[6].split('|'))
        if (c.trim().isNotEmpty) c.trim(),
    ],
    notes: notes.trim().isEmpty ? null : notes,
  );
}
