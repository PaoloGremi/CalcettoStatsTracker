import 'package:calcetto_tracker/features/trainings/domain/entities/training.dart';
import 'package:calcetto_tracker/features/trainings/domain/training_validation.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime(2026, 10, 24, 10);

Training _run({double? km = 5.0, int? seconds = 1500, DateTime? date}) =>
    Training(
      id: 'r',
      date: date ?? DateTime(2026, 10, 20),
      type: TrainingType.running,
      distanceKm: km,
      runSeconds: seconds,
    );

Training _technical({
  int? minutes = 60,
  Set<TechnicalCategory> categories = const {TechnicalCategory.shots},
}) =>
    Training(
      id: 't',
      date: DateTime(2026, 10, 20),
      type: TrainingType.technical,
      durationMinutes: minutes,
      categories: categories,
    );

Training _mixed() => Training(
      id: 'm',
      date: DateTime(2026, 10, 20),
      type: TrainingType.mixed,
      durationMinutes: 60,
      distanceKm: 5.0,
      runSeconds: 1500,
      categories: const {TechnicalCategory.shots},
      notes: 'ok',
    );

void main() {
  group('derived values', () {
    test('pace is run seconds divided by km', () {
      expect(_run().paceSecondsPerKm, 300);
    });

    test('pace is null without run data', () {
      expect(_technical().paceSecondsPerKm, isNull);
    });

    test('totalMinutes of a run comes from run seconds', () {
      expect(_run(seconds: 1530).totalMinutes, 26);
    });

    test('totalMinutes of a technical session is its duration', () {
      expect(_technical(minutes: 45).totalMinutes, 45);
    });

    test('type flags', () {
      expect(TrainingType.running.hasDistance, isTrue);
      expect(TrainingType.running.countsAsRun, isTrue);
      expect(TrainingType.running.hasTechnical, isFalse);
      expect(TrainingType.walking.hasDistance, isTrue);
      expect(TrainingType.walking.countsAsRun, isFalse);
      expect(TrainingType.walking.hasTechnical, isFalse);
      expect(TrainingType.technical.hasDistance, isFalse);
      expect(TrainingType.technical.countsAsRun, isFalse);
      expect(TrainingType.technical.hasTechnical, isTrue);
      expect(TrainingType.mixed.hasDistance, isTrue);
      expect(TrainingType.mixed.countsAsRun, isTrue);
      expect(TrainingType.mixed.hasTechnical, isTrue);
    });

    test('walking label', () {
      expect(TrainingType.walking.label, 'Camminata');
    });

    test('walking pace and total minutes come from distance and time', () {
      final walk = Training(
        id: 'w',
        date: DateTime(2026, 10, 20),
        type: TrainingType.walking,
        distanceKm: 4,
        runSeconds: 2760,
      );
      expect(walk.paceSecondsPerKm, 690);
      expect(walk.totalMinutes, 46);
    });
  });

  group('normalized', () {
    test('drops technical fields when switching to running', () {
      final t = _mixed().copyWith(type: TrainingType.running).normalized();

      expect(t.durationMinutes, isNull);
      expect(t.categories, isEmpty);
      expect(t.distanceKm, 5.0);
      expect(t.runSeconds, 1500);
    });

    test('drops technical fields when switching to walking', () {
      final t = _mixed().copyWith(type: TrainingType.walking).normalized();

      expect(t.durationMinutes, isNull);
      expect(t.categories, isEmpty);
      expect(t.distanceKm, 5.0);
      expect(t.runSeconds, 1500);
    });

    test('drops run fields for technical', () {
      final t = _mixed().copyWith(type: TrainingType.technical).normalized();

      expect(t.distanceKm, isNull);
      expect(t.runSeconds, isNull);
      expect(t.durationMinutes, 60);
      expect(t.categories, {TechnicalCategory.shots});
    });

    test('strips time and blank notes', () {
      final t = _run(date: DateTime(2026, 10, 23, 23, 30))
          .copyWith(notes: '  ')
          .normalized();

      expect(t.date, DateTime(2026, 10, 23));
      expect(t.notes, isNull);
    });

    test('trims notes', () {
      expect(_run().copyWith(notes: ' bene ').normalized().notes, 'bene');
    });
  });

  group('validateTraining', () {
    test('future date', () {
      expect(validateTraining(_run(date: DateTime(2026, 10, 25)), today: _today),
          'La data non può essere nel futuro');
    });

    test('today late evening is valid', () {
      expect(
          validateTraining(_run(date: DateTime(2026, 10, 24, 23, 59)),
              today: _today),
          isNull);
    });

    test('missing distance', () {
      expect(validateTraining(_run(km: 0), today: _today),
          'Inserisci una distanza maggiore di zero');
    });

    test('non-finite distance', () {
      expect(validateTraining(_run(km: double.nan), today: _today),
          'Inserisci una distanza maggiore di zero');
      expect(validateTraining(_run(km: double.infinity), today: _today),
          'Inserisci una distanza maggiore di zero');
    });

    test('missing run time', () {
      expect(validateTraining(_run(seconds: null), today: _today),
          'Inserisci un tempo di corsa maggiore di zero');
    });

    test('walking without distance', () {
      expect(
          validateTraining(
              _run(km: null).copyWith(type: TrainingType.walking),
              today: _today),
          'Inserisci una distanza maggiore di zero');
    });

    test('walking without time uses a generic message', () {
      expect(
          validateTraining(
              _run(seconds: null).copyWith(type: TrainingType.walking),
              today: _today),
          'Inserisci un tempo maggiore di zero');
    });

    test('missing duration', () {
      expect(validateTraining(_technical(minutes: null), today: _today),
          'Inserisci una durata maggiore di zero');
    });

    test('missing categories', () {
      expect(validateTraining(_technical(categories: const {}), today: _today),
          'Scegli almeno una categoria tecnica');
    });

    test('valid mixed training returns null', () {
      expect(validateTraining(_mixed(), today: _today), isNull);
    });
  });

  group('swimming', () {
    final swim = Training(
      id: 's',
      date: DateTime(2026, 10, 20),
      type: TrainingType.swimming,
      durationMinutes: 45,
    );

    test('label and flags: duration only', () {
      expect(TrainingType.swimming.label, 'Nuoto');
      expect(TrainingType.swimming.hasDistance, isFalse);
      expect(TrainingType.swimming.countsAsRun, isFalse);
      expect(TrainingType.swimming.hasTechnical, isFalse);
      expect(TrainingType.swimming.hasDuration, isTrue);
    });

    test('duration flag for the other types', () {
      expect(TrainingType.running.hasDuration, isFalse);
      expect(TrainingType.walking.hasDuration, isFalse);
      expect(TrainingType.technical.hasDuration, isTrue);
      expect(TrainingType.mixed.hasDuration, isTrue);
    });

    test('total minutes is the duration', () {
      expect(swim.totalMinutes, 45);
    });

    test('normalized keeps the duration and drops everything else', () {
      final t = swim
          .copyWith(
            distanceKm: 1.5,
            runSeconds: 1800,
            categories: {TechnicalCategory.shots},
          )
          .normalized();
      expect(t.durationMinutes, 45);
      expect(t.distanceKm, isNull);
      expect(t.runSeconds, isNull);
      expect(t.categories, isEmpty);
    });

    test('valid without distance or categories', () {
      expect(validateTraining(swim, today: _today), isNull);
    });

    test('requires a duration', () {
      final noDuration = Training(
          id: 's', date: DateTime(2026, 10, 20), type: TrainingType.swimming);
      expect(validateTraining(noDuration, today: _today),
          'Inserisci una durata maggiore di zero');
    });
  });
}
