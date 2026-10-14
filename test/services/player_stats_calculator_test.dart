import 'dart:io';

import 'package:calcetto_tracker/data/hive_boxes.dart';
import 'package:calcetto_tracker/models/field_model.dart';
import 'package:calcetto_tracker/models/match_model.dart';
import 'package:calcetto_tracker/models/player_model.dart';
import 'package:calcetto_tracker/services/player_stats_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('player_stats_calc_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PlayerModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MatchModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FieldModelAdapter());
    HiveBoxes.playersBox = await Hive.openBox<PlayerModel>('playersBox');
    HiveBoxes.matchesBox = await Hive.openBox<MatchModel>('matchesBox');
    HiveBoxes.fieldsBox = await Hive.openBox<FieldModel>('fieldsBox');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<void> addMatch(String id, DateTime date,
      {List<String> a = const ['p1', 'x'],
      List<String> b = const ['y', 'z'],
      int sa = 0,
      int sb = 0,
      Map<String, double>? votes}) async {
    final m = MatchModel(
        id: id,
        date: date,
        teamA: a,
        teamB: b,
        scoreA: sa,
        scoreB: sb,
        votes: votes,
        fieldLocation: 'f1',
        mvp: '',
        hustlePlayer: '');
    await HiveBoxes.matchesBox.put(id, m);
  }

  group('FIS', () {
    test('regular combative defender gets a high physical score', () async {
      await HiveBoxes.playersBox.put(
          'p1',
          PlayerModel(
              id: 'p1', name: 'Mario', role: 'D', icon: 'x', hustleCount: 1));
      // 3 partite giocate su 4 registrate: V, P, V con voto 7.
      await addMatch('m1', DateTime(2026, 1, 1),
          sa: 3, sb: 1, votes: {'p1': 7});
      await addMatch('m2', DateTime(2026, 1, 8),
          sa: 2, sb: 2, votes: {'p1': 7});
      await addMatch('m3', DateTime(2026, 1, 15),
          sa: 4, sb: 0, votes: {'p1': 7});
      await addMatch('m4', DateTime(2026, 1, 22), a: ['x', 'w'], sa: 1, sb: 0);

      // presenze 75% → 99·0.30 = 29.70
      // combattivo 1/3 ≥ 0.2 → 99·0.25 = 24.75
      // imbattuto 3 → 69.5·0.20 = 13.90
      // ruolo D → 99·0.15 = 14.85
      // voto 7 → 79.33·0.10 = 7.93            totale 91.13 → 91
      expect(PlayerStatsCalculator.compute('p1').fis, 91);
    });

    test('single lost match, no votes, attacker', () async {
      await HiveBoxes.playersBox.put(
          'p1', PlayerModel(id: 'p1', name: 'Mario', role: 'A', icon: 'x'));
      await addMatch('m1', DateTime(2026, 1, 1), sa: 0, sb: 2);

      // presenze 100% → 29.70 · combattivo 0 → 45·0.25 = 11.25
      // imbattuto 0 → 40·0.20 = 8.00 · ruolo A → 65·0.15 = 9.75
      // voto (default 6.0) → 59.67·0.10 = 5.97          totale 64.67 → 65
      expect(PlayerStatsCalculator.compute('p1').fis, 65);
    });

    test('stays within 40–99', () async {
      await HiveBoxes.playersBox.put(
          'p1',
          PlayerModel(
              id: 'p1', name: 'Mario', role: 'D', icon: 'x', hustleCount: 9));
      for (var i = 0; i < 9; i++) {
        await addMatch('m$i', DateTime(2026, 1, i + 1),
            sa: 3, sb: 0, votes: {'p1': 10});
      }
      final fis = PlayerStatsCalculator.compute('p1').fis;
      expect(fis, inInclusiveRange(40, 99));
      expect(fis, 99);
    });
  });

  group('fisRoleScore', () {
    test('recognises the single-letter roles saved by the app', () {
      expect(PlayerStatsCalculator.fisRoleScore('D'), 99);
      expect(PlayerStatsCalculator.fisRoleScore('P'), 90);
      expect(PlayerStatsCalculator.fisRoleScore('C'), 80);
      expect(PlayerStatsCalculator.fisRoleScore('A'), 65);
    });

    test('still recognises long role names and is case-insensitive', () {
      expect(PlayerStatsCalculator.fisRoleScore('Difensore'), 99);
      expect(PlayerStatsCalculator.fisRoleScore('portiere'), 90);
      expect(PlayerStatsCalculator.fisRoleScore('CENTROCAMPISTA'), 80);
      expect(PlayerStatsCalculator.fisRoleScore('Attaccante'), 65);
    });

    test('unknown or empty role gets the attacker score', () {
      expect(PlayerStatsCalculator.fisRoleScore(''), 65);
      expect(PlayerStatsCalculator.fisRoleScore('?'), 65);
    });
  });

  group('VEL / TIR / PAS / DRI / DIF', () {
    // 4 partite registrate (più di 60 giorni fa → frequenza recente al
    // minimo). p1 ne gioca 3, sempre in squadra A:
    //   m1 5–3 V, 2 gol, voto 7 · m2 4–6 S, 0 gol, voto 6
    //   m3 6–6 P, 1 gol, voto 8 · m4 3–5 senza p1
    // p1: centrocampista, 1 MVP, 1 Best Goal, 1 Combattivo.
    Future<void> seedFixture() async {
      await HiveBoxes.playersBox.put(
          'p1',
          PlayerModel(
              id: 'p1',
              name: 'Mario',
              role: 'C',
              icon: 'x',
              mvpCount: 1,
              bestGoalCount: 1,
              hustleCount: 1));
      Future<void> add(
          String id, int day, int sa, int sb, int goals, double vote) async {
        final m = MatchModel(
            id: id,
            date: DateTime(2025, 1, day),
            teamA: const ['p1', 'x'],
            teamB: const ['y', 'z'],
            scoreA: sa,
            scoreB: sb,
            votes: {'p1': vote, 'x': 6},
            goals: {'p1': goals},
            fieldLocation: 'f1',
            mvp: '',
            hustlePlayer: '');
        await HiveBoxes.matchesBox.put(id, m);
      }

      await add('m1', 1, 5, 3, 2, 7);
      await add('m2', 8, 4, 6, 0, 6);
      await add('m3', 15, 6, 6, 1, 8);
      await addMatch('m4', DateTime(2025, 1, 22), a: ['x', 'w'], sa: 3, sb: 5);
    }

    test('VEL: recent frequency, goals per game, scoring rate', () async {
      await seedFixture();
      // recente 0 → 40·0.35 = 14.00 · gol/p 1.0 → 69.5·0.40 = 27.80
      // a segno 2/3 → 89.17·0.25 = 22.29                 totale 64.09 → 64
      expect(PlayerStatsCalculator.compute('p1').vel, 64);
    });

    test('TIR: goals per game plus MVP and Best Goal bonus', () async {
      await seedFixture();
      // gol/p 1.0 → 66 · +1 MVP · +2 Best Goal → 69
      expect(PlayerStatsCalculator.compute('p1').tir, 69);
    });

    test('PAS: teammate goals, win rate, presence, vote', () async {
      await seedFixture();
      // compagni 4.0/p → 51.8·0.30 = 15.54 · vittorie 1/3 → 55.73·0.30 = 16.72
      // presenze 75% → 99·0.20 = 19.80 · voto 7 → 79.33·0.20 = 15.87
      //                                                  totale 67.93 → 68
      expect(PlayerStatsCalculator.compute('p1').pas, 68);
    });

    test('DRI: goals per game, MVP rate, vote', () async {
      await seedFixture();
      // gol/p 1.0 → 69.5·0.40 = 27.80 · MVP 1/3 → 99·0.35 = 34.65
      // voto 7 → 79.33·0.25 = 19.83                      totale 82.28 → 82
      expect(PlayerStatsCalculator.compute('p1').dri, 82);
    });

    test('DIF: conceded vs group average, combative, role, vote in losses',
        () async {
      await seedFixture();
      // subiti 5.0/p vs media gruppo 38/8 = 4.75 → rapporto 1.053
      //   → 64.32·0.35 = 22.51 · Combattivo 1/3 → 99·0.25 = 24.75
      // ruolo C → 75·0.20 = 15.00 · voto sconfitte 6 → 69.5·0.20 = 13.90
      //                                                  totale 76.16 → 76
      expect(PlayerStatsCalculator.compute('p1').dif, 76);
    });

    test('FIS is unchanged by the other stats', () async {
      await seedFixture();
      // presenze 29.70 · Combattivo 24.75 · imbattuto 1 → 49.83·0.20 = 9.97
      // ruolo C 80·0.15 = 12.00 · voto 7 → 7.93          totale 84.35 → 84
      expect(PlayerStatsCalculator.compute('p1').fis, 84);
    });

    test('DIF is neutral on conceded goals when the group never concedes',
        () async {
      await HiveBoxes.playersBox.put(
          'p1', PlayerModel(id: 'p1', name: 'Mario', role: 'D', icon: 'x'));
      await addMatch('m1', DateTime(2025, 1, 1));
      // rapporto neutro 1.0 → 69.5·0.35 = 24.33 · Combattivo 0 → 45·0.25 = 11.25
      // ruolo D 99·0.20 = 19.80 · voto (default 6.0) → 69.5·0.20 = 13.90
      //                                                  totale 69.28 → 69
      expect(PlayerStatsCalculator.compute('p1').dif, 69);
    });

    test('every stat stays within 40–99', () async {
      await HiveBoxes.playersBox.put(
          'p1',
          PlayerModel(
              id: 'p1',
              name: 'Mario',
              role: 'A',
              icon: 'x',
              mvpCount: 50,
              bestGoalCount: 50,
              hustleCount: 50));
      for (var i = 0; i < 5; i++) {
        await HiveBoxes.matchesBox.put(
            'm$i',
            MatchModel(
                id: 'm$i',
                date: DateTime(2025, 1, i + 1),
                teamA: const ['p1'],
                teamB: const ['y'],
                scoreA: 12,
                scoreB: 0,
                votes: {'p1': 10},
                goals: {'p1': 12},
                fieldLocation: 'f1',
                mvp: '',
                hustlePlayer: ''));
      }
      final s = PlayerStatsCalculator.compute('p1');
      for (final v in [s.vel, s.tir, s.pas, s.dri, s.dif, s.fis]) {
        expect(v, inInclusiveRange(40, 99));
      }
    });
  });

  group('difRoleScore', () {
    test('single letters and long names', () {
      expect(PlayerStatsCalculator.difRoleScore('D'), 99);
      expect(PlayerStatsCalculator.difRoleScore('Difensore'), 99);
      expect(PlayerStatsCalculator.difRoleScore('P'), 95);
      expect(PlayerStatsCalculator.difRoleScore('portiere'), 95);
      expect(PlayerStatsCalculator.difRoleScore('C'), 75);
      expect(PlayerStatsCalculator.difRoleScore('Centrocampista'), 75);
      expect(PlayerStatsCalculator.difRoleScore('A'), 55);
      expect(PlayerStatsCalculator.difRoleScore(''), 55);
    });
  });
}
