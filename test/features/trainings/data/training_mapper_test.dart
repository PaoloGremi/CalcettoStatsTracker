import 'package:calcetto_tracker/features/trainings/data/mappers/training_mapper.dart';
import 'package:calcetto_tracker/features/trainings/data/models/training_model.dart';
import 'package:calcetto_tracker/features/trainings/domain/entities/training.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = TrainingMapper();

  test('round trips every field', () {
    final t = Training(
      id: 'a',
      date: DateTime(2026, 10, 20),
      type: TrainingType.mixed,
      durationMinutes: 60,
      distanceKm: 5.2,
      runSeconds: 1530,
      categories: const {TechnicalCategory.shots, TechnicalCategory.strength},
      notes: 'note',
    );

    final model = mapper.toModel(t);
    expect(model.type, 'mixed');
    expect(model.categories, unorderedEquals(['shots', 'strength']));

    final back = mapper.toEntity(model);
    expect(back.id, 'a');
    expect(back.date, DateTime(2026, 10, 20));
    expect(back.type, TrainingType.mixed);
    expect(back.durationMinutes, 60);
    expect(back.distanceKm, 5.2);
    expect(back.runSeconds, 1530);
    expect(back.categories,
        {TechnicalCategory.shots, TechnicalCategory.strength});
    expect(back.notes, 'note');
  });

  test('unknown category names are dropped', () {
    final model = TrainingModel(
      id: 'a',
      date: DateTime(2026, 10, 20),
      type: 'technical',
      durationMinutes: 30,
      categories: ['shots', 'juggling'],
    );

    expect(mapper.toEntity(model).categories, {TechnicalCategory.shots});
  });

  test('unknown type falls back to mixed', () {
    final model =
        TrainingModel(id: 'a', date: DateTime(2026, 10, 20), type: 'yoga');

    expect(mapper.toEntity(model).type, TrainingType.mixed);
  });
}
