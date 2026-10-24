import 'package:calcetto_tracker/features/trainings/domain/entities/training.dart';
import 'package:calcetto_tracker/features/trainings/domain/services/training_stats.dart';
import 'package:flutter_test/flutter_test.dart';

int _n = 0;

Training _run(DateTime date, double km, int seconds) => Training(
      id: 'r${_n++}',
      date: date,
      type: TrainingType.running,
      distanceKm: km,
      runSeconds: seconds,
    );

Training _tech(DateTime date) => Training(
      id: 't${_n++}',
      date: date,
      type: TrainingType.technical,
      durationMinutes: 60,
      categories: const {TechnicalCategory.shots},
    );

Training _mixed(DateTime date, double km, int seconds) => Training(
      id: 'm${_n++}',
      date: date,
      type: TrainingType.mixed,
      durationMinutes: 60,
      distanceKm: km,
      runSeconds: seconds,
      categories: const {TechnicalCategory.sprint},
    );

Training _walk(DateTime date, double km, int seconds) => Training(
      id: 'w${_n++}',
      date: date,
      type: TrainingType.walking,
      distanceKm: km,
      runSeconds: seconds,
    );

final _today = DateTime(2026, 10, 21); // mercoledì

void main() {
  test('empty list gives nulls and zeros', () {
    final s = TrainingStats(const [], today: _today);

    expect(s.bestPaceSecondsPerKm, isNull);
    expect(s.longestRunKm, isNull);
    expect(s.bestWeekStreak, 0);
    expect(s.currentWeekStreak, 0);
    expect(s.pacePoints, isEmpty);
    expect(s.dayTypes, isEmpty);
    expect(s.activeYears, isEmpty);
    expect(s.thisWeekCount, 0);
    expect(s.latest, isNull);
    expect(s.longestWalkKm, isNull);
    expect(s.walkPacePoints, isEmpty);
  });

  test('walks stay out of run records and run pace points', () {
    final s = TrainingStats([
      _run(DateTime(2026, 10, 1), 5, 1500),
      _walk(DateTime(2026, 10, 2), 9, 3000), // 333 s/km, più lunga
      _walk(DateTime(2026, 10, 3), 2, 400), // 200 s/km, più veloce
    ], today: _today);

    expect(s.bestPaceSecondsPerKm, 300);
    expect(s.longestRunKm, 5);
    expect(s.pacePoints, hasLength(1));
  });

  test('walking records and pace points', () {
    final s = TrainingStats([
      _walk(DateTime(2026, 10, 5), 6, 4200),
      _run(DateTime(2026, 10, 4), 10, 3000),
      _walk(DateTime(2026, 10, 2), 4, 2760),
    ], today: _today);

    expect(s.longestWalkKm, 6);
    expect(s.walkPacePoints.map((p) => p.date),
        [DateTime(2026, 10, 2), DateTime(2026, 10, 5)]);
    expect(s.walkPacePoints.first.secondsPerKm, 690);
  });

  test('walks count for streaks, week count and day types', () {
    final s = TrainingStats([
      _walk(DateTime(2026, 10, 20), 4, 2760),
      _walk(DateTime(2026, 10, 13), 4, 2760),
    ], today: _today);

    expect(s.currentWeekStreak, 2);
    expect(s.thisWeekCount, 1);
    expect(s.dayTypes[DateTime.utc(2026, 10, 20)], TrainingType.walking);
  });

  test('best pace ignores runs shorter than 1 km', () {
    final s = TrainingStats([
      _run(DateTime(2026, 10, 1), 0.4, 80),
      _run(DateTime(2026, 10, 2), 5, 1500),
    ], today: _today);

    expect(s.bestPaceSecondsPerKm, 300);
  });

  test('exactly 1 km counts for best pace', () {
    final s = TrainingStats([
      _run(DateTime(2026, 10, 1), 1.0, 240),
      _run(DateTime(2026, 10, 2), 5, 1500),
    ], today: _today);

    expect(s.bestPaceSecondsPerKm, 240);
  });

  test('longest run includes mixed trainings', () {
    final s = TrainingStats([
      _run(DateTime(2026, 10, 1), 5, 1500),
      _mixed(DateTime(2026, 10, 2), 8, 2600),
      _tech(DateTime(2026, 10, 3)),
    ], today: _today);

    expect(s.longestRunKm, 8);
  });

  test('week streak spans the new year', () {
    final s = TrainingStats([
      _tech(DateTime(2025, 12, 24)),
      _tech(DateTime(2025, 12, 31)),
      _tech(DateTime(2026, 1, 7)),
    ], today: _today);

    expect(s.bestWeekStreak, 3);
  });

  test('two trainings in the same week count once', () {
    final s = TrainingStats([
      _tech(DateTime(2026, 10, 5)),
      _tech(DateTime(2026, 10, 11)),
    ], today: _today);

    expect(s.bestWeekStreak, 1);
  });

  test('current streak survives an empty current week', () {
    final s = TrainingStats([
      _tech(DateTime(2026, 10, 12)),
      _tech(DateTime(2026, 10, 5)),
    ], today: _today);

    expect(s.currentWeekStreak, 2);
  });

  test('current streak includes the current week', () {
    final s = TrainingStats([
      _tech(DateTime(2026, 10, 19)),
      _tech(DateTime(2026, 10, 12)),
    ], today: _today);

    expect(s.currentWeekStreak, 2);
  });

  test('current streak resets after a full empty week', () {
    final s = TrainingStats([_tech(DateTime(2026, 10, 1))], today: _today);

    expect(s.currentWeekStreak, 0);
    expect(s.bestWeekStreak, 1);
  });

  test('late-evening training lands on its own day', () {
    final s = TrainingStats([_tech(DateTime(2026, 3, 29, 23, 30))],
        today: _today);

    expect(s.dayTypes.keys, [DateTime.utc(2026, 3, 29)]);
  });

  test('different types on the same day become mixed', () {
    final s = TrainingStats([
      _run(DateTime(2026, 10, 1), 5, 1500),
      _tech(DateTime(2026, 10, 1)),
      _tech(DateTime(2026, 10, 2)),
    ], today: _today);

    expect(s.dayTypes[DateTime.utc(2026, 10, 1)], TrainingType.mixed);
    expect(s.dayTypes[DateTime.utc(2026, 10, 2)], TrainingType.technical);
  });

  test('pace points are sorted by date', () {
    final s = TrainingStats([
      _run(DateTime(2026, 10, 3), 5, 1400),
      _tech(DateTime(2026, 10, 2)),
      _mixed(DateTime(2026, 10, 1), 4, 1300),
    ], today: _today);

    expect(s.pacePoints.map((p) => p.date),
        [DateTime(2026, 10, 1), DateTime(2026, 10, 3)]);
    expect(s.pacePoints.first.secondsPerKm, 325);
  });

  test('thisWeekCount counts Monday to Sunday', () {
    final s = TrainingStats([
      _tech(DateTime(2026, 10, 18)), // domenica precedente
      _tech(DateTime(2026, 10, 19)), // lunedì
      _tech(DateTime(2026, 10, 21)),
      _tech(DateTime(2026, 10, 21)),
    ], today: _today);

    expect(s.thisWeekCount, 3);
  });

  test('latest is the most recent', () {
    final recent = _tech(DateTime(2026, 10, 20));
    final s = TrainingStats([
      _tech(DateTime(2026, 10, 1)),
      recent,
      _tech(DateTime(2026, 9, 1)),
    ], today: _today);

    expect(s.latest, same(recent));
  });

  test('activeYears are sorted and unique', () {
    final s = TrainingStats([
      _tech(DateTime(2026, 1, 1)),
      _tech(DateTime(2024, 5, 1)),
      _tech(DateTime(2026, 2, 1)),
    ], today: _today);

    expect(s.activeYears, [2024, 2026]);
  });

  test('swims stay out of run and walk records but count for streaks', () {
    final swim = Training(
      id: 's',
      date: DateTime(2026, 10, 20),
      type: TrainingType.swimming,
      durationMinutes: 45,
    );
    final s = TrainingStats([swim], today: DateTime(2026, 10, 24));

    expect(s.bestPaceSecondsPerKm, isNull);
    expect(s.longestRunKm, isNull);
    expect(s.longestWalkKm, isNull);
    expect(s.pacePoints, isEmpty);
    expect(s.walkPacePoints, isEmpty);
    expect(s.currentWeekStreak, 1);
    expect(s.thisWeekCount, 1);
    expect(s.dayTypes[DateTime.utc(2026, 10, 20)], TrainingType.swimming);
  });
}
