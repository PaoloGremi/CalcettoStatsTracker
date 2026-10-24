import 'package:calcetto_tracker/features/calendar/domain/activity_calendar.dart';
import 'package:calcetto_tracker/features/trainings/domain/entities/training.dart';
import 'package:calcetto_tracker/models/match_model.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match(String id, DateTime date, {List<String> teamA = const ['me']}) =>
    MatchModel(
      id: id,
      date: date,
      teamA: teamA,
      teamB: const ['x'],
      fieldLocation: '',
      mvp: '',
      hustlePlayer: '',
    );

Training _training(String id, DateTime date) =>
    Training(id: id, date: date, type: TrainingType.running);

void main() {
  test('groups matches and trainings by day, ignoring the time', () {
    final cal = ActivityCalendar(
      matches: [_match('m1', DateTime(2026, 10, 14, 21, 0))],
      trainings: [_training('t1', DateTime(2026, 10, 14))],
    );

    final entries = cal.entriesOn(DateTime(2026, 10, 14, 9, 30));

    expect(entries, hasLength(2));
    expect(entries.whereType<MatchEntry>().single.match.id, 'm1');
    expect(entries.whereType<TrainingEntry>().single.training.id, 't1');
    expect(cal.entriesOn(DateTime(2026, 10, 15)), isEmpty);
  });

  test('keeps only matches the player took part in, from either team', () {
    final cal = ActivityCalendar(
      playerId: 'me',
      matches: [
        _match('a', DateTime(2026, 10, 1), teamA: const ['me']),
        _match('b', DateTime(2026, 10, 1), teamA: const ['other']),
        MatchModel(
          id: 'c',
          date: DateTime(2026, 10, 1),
          teamA: const ['other'],
          teamB: const ['me'],
          fieldLocation: '',
          mvp: '',
          hustlePlayer: '',
        ),
      ],
      trainings: const [],
    );

    final ids = cal
        .entriesOn(DateTime(2026, 10, 1))
        .whereType<MatchEntry>()
        .map((e) => e.match.id);
    expect(ids, unorderedEquals(['a', 'c']));
  });

  test('without a player shows every match', () {
    final cal = ActivityCalendar(
      matches: [_match('b', DateTime(2026, 10, 1), teamA: const ['other'])],
      trainings: const [],
    );

    expect(cal.entriesOn(DateTime(2026, 10, 1)), hasLength(1));
  });

  test('a day lists matches first, then trainings, each by time', () {
    final cal = ActivityCalendar(
      matches: [
        _match('late', DateTime(2026, 10, 3, 21)),
        _match('early', DateTime(2026, 10, 3, 18)),
      ],
      trainings: [_training('t', DateTime(2026, 10, 3))],
    );

    final entries = cal.entriesOn(DateTime(2026, 10, 3));

    expect(entries[0], isA<MatchEntry>());
    expect((entries[0] as MatchEntry).match.id, 'early');
    expect((entries[1] as MatchEntry).match.id, 'late');
    expect(entries[2], isA<TrainingEntry>());
  });

  test('years lists every year with at least one entry', () {
    final cal = ActivityCalendar(
      playerId: 'me',
      matches: [
        _match('a', DateTime(2024, 5, 1)),
        _match('other', DateTime(2023, 5, 1), teamA: const ['other']),
      ],
      trainings: [_training('t', DateTime(2026, 1, 1))],
    );

    expect(cal.years, {2024, 2026});
  });

  test('month counts include only that month', () {
    final cal = ActivityCalendar(
      matches: [
        _match('sep', DateTime(2026, 9, 30, 21)),
        _match('oct1', DateTime(2026, 10, 1)),
        _match('oct31', DateTime(2026, 10, 31, 23, 59)),
      ],
      trainings: [
        _training('t1', DateTime(2026, 10, 5)),
        _training('nov', DateTime(2026, 11, 1)),
      ],
    );

    final counts = cal.monthCounts(2026, 10);

    expect(counts.matches, 2);
    expect(counts.trainings, 1);
  });
}
