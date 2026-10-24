import 'package:calcetto_tracker/features/trainings/data/models/training_model.dart';
import 'package:calcetto_tracker/features/trainings/data/training_csv.dart';
import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stessi parametri di `CsvService._toCsv` / `_fromCsv`.
List<List<dynamic>> _throughCsv(List<List<String>> rows) {
  final text = const ListToCsvConverter(
    fieldDelimiter: ',',
    textDelimiter: '"',
    textEndDelimiter: '"',
    eol: '\n',
  ).convert(rows);
  return const CsvToListConverter(
    fieldDelimiter: ',',
    textDelimiter: '"',
    textEndDelimiter: '"',
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(text);
}

void main() {
  test('round trip keeps every field', () {
    final original = TrainingModel(
      id: 'abc',
      date: DateTime(2026, 10, 20),
      type: 'mixed',
      durationMinutes: 60,
      distanceKm: 5.25,
      runSeconds: 1530,
      categories: ['shots', 'sprint'],
      notes: 'Ripetute, "lente"\nseconda riga',
    );

    final rows = _throughCsv(trainingsToCsvRows([original]));
    expect(rows.first, trainingCsvHeader);

    final back = trainingFromCsvRow(rows[1])!;
    expect(back.id, 'abc');
    expect(back.date, DateTime(2026, 10, 20));
    expect(back.type, 'mixed');
    expect(back.durationMinutes, 60);
    expect(back.distanceKm, 5.25);
    expect(back.runSeconds, 1530);
    expect(back.categories, ['shots', 'sprint']);
    expect(back.notes, 'Ripetute, "lente"\nseconda riga');
  });

  test('technical row has empty run columns', () {
    final model = TrainingModel(
      id: 't',
      date: DateTime(2026, 10, 20),
      type: 'technical',
      durationMinutes: 45,
      categories: ['strength'],
    );

    final row = trainingsToCsvRows([model])[1];
    expect(row, ['t', '20/10/2026', 'technical', '45', '', '', 'strength', '']);

    final back = trainingFromCsvRow(row)!;
    expect(back.distanceKm, isNull);
    expect(back.runSeconds, isNull);
    expect(back.notes, isNull);
  });

  test('invalid date returns null', () {
    expect(
        trainingFromCsvRow(
            ['a', '31/02/2026', 'running', '', '5', '1500', '', '']),
        isNull);
  });

  test('unknown type returns null', () {
    expect(
        trainingFromCsvRow(['a', '20/10/2026', 'yoga', '30', '', '', '', '']),
        isNull);
  });

  test('short row returns null', () {
    expect(trainingFromCsvRow(['a', '20/10/2026']), isNull);
  });

  test('empty id returns null', () {
    expect(
        trainingFromCsvRow(['', '20/10/2026', 'running', '', '5', '1500', '', '']),
        isNull);
  });
}
