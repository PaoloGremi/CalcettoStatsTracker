import 'dart:io';

import 'package:calcetto_tracker/data/hive_boxes.dart';
import 'package:calcetto_tracker/models/field_model.dart';
import 'package:calcetto_tracker/models/match_model.dart';
import 'package:calcetto_tracker/models/player_model.dart';
import 'package:calcetto_tracker/screens/match_detail_screen.dart';
import 'package:calcetto_tracker/screens/player_stats_screen.dart';
import 'package:calcetto_tracker/services/data_service.dart';
import 'package:calcetto_tracker/services/player_stats_summary.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main() {
  late Directory tempDir;
  late DataService dataService;
  late PlayerModel mario;

  setUpAll(() => initializeDateFormatting('it_IT'));

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('player_stats_screen_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PlayerModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MatchModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FieldModelAdapter());
    HiveBoxes.playersBox = await Hive.openBox<PlayerModel>('playersBox');
    HiveBoxes.matchesBox = await Hive.openBox<MatchModel>('matchesBox');
    HiveBoxes.fieldsBox = await Hive.openBox<FieldModel>('fieldsBox');
    mario = PlayerModel(id: 'p1', name: 'Mario', role: 'A', icon: 'star');
    final luigi = PlayerModel(id: 'p2', name: 'Luigi', role: 'D', icon: 'star');
    await HiveBoxes.playersBox.put(mario.id, mario);
    await HiveBoxes.playersBox.put(luigi.id, luigi);
    dataService = DataService();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// 6 partite di Mario (p1) contro Luigi (p2), una al mese.
  List<MatchModel> sixMatches({bool withVotes = true}) => [
        for (int i = 0; i < 6; i++)
          MatchModel(
            id: 'm$i',
            date: DateTime(2026, i + 1, 10),
            teamA: const ['p1'],
            teamB: const ['p2'],
            scoreA: i % 3,
            scoreB: 1,
            votes: withVotes ? {'p1': 5.0 + i % 3, 'p2': 6.0} : null,
            goals: {'p1': i % 3},
            fieldLocation: '',
            mvp: '',
            hustlePlayer: '',
          ),
      ];

  Future<void> seed(WidgetTester tester, List<MatchModel> matches) async {
    await tester.runAsync(() async {
      for (final m in matches) {
        await HiveBoxes.matchesBox.put(m.id, m);
      }
    });
  }

  Future<void> pumpScreen(WidgetTester tester, {DateTime? today}) async {
    // Provider sopra il MaterialApp: le route spinte (MatchDetailScreen) lo vedono.
    await tester.pumpWidget(ChangeNotifierProvider<DataService>.value(
      value: dataService,
      child: MaterialApp(home: PlayerStatsScreen(player: mario, today: today)),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(
        find.descendant(of: find.byType(TabBar), matching: find.text(label)));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'shows the empty message and no tabs when the player has no matches',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Nessuna partita registrata per questo giocatore.'),
        findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('shows the 7 tabs in order', (tester) async {
    await seed(tester, sixMatches());
    await pumpScreen(tester);

    expect(find.byType(Tab), findsNWidgets(7));
    const labels = [
      'PANORAMICA',
      'VOTI',
      'GOL',
      'RISULTATI',
      'RECORD',
      'COMPAGNI',
      'STAGIONI',
    ];
    final tabTexts = [
      for (final tab in find.byType(Tab).evaluate())
        tester
            .widget<Text>(find.descendant(
                of: find.byWidget(tab.widget), matching: find.byType(Text)))
            .data,
    ];
    expect(tabTexts, labels);
    // Ogni tab ha la sua icona.
    expect(find.descendant(of: find.byType(Tab), matching: find.byType(Icon)),
        findsNWidgets(7));
  });

  testWidgets('tabs fill the whole width without overflowing on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // Raccoglie gli errori di layout; quelli dei riquadri _StatBox della
    // Panoramica (stats_widgets.dart) sono un problema noto e separato
    // degli schermi stretti, non della barra delle tab.
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.toString());
    await seed(tester, sixMatches());
    await pumpScreen(tester);
    FlutterError.onError = previous;

    expect(errors.where((e) => !e.contains('stats_widgets.dart')), isEmpty);
    final tabs = find.byType(Tab);
    expect(tester.getRect(tabs.first).left, lessThanOrEqualTo(8));
    expect(tester.getRect(tabs.last).right, greaterThanOrEqualTo(312));
    // Tutte le tab sono visibili insieme: niente scroll orizzontale.
    for (final e in tabs.evaluate()) {
      final r = tester.getRect(find.byWidget(e.widget));
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(320));
    }
  });

  testWidgets('radar uses a fixed 0–1 scale in both views', (tester) async {
    await seed(tester, sixMatches());
    await pumpScreen(tester);
    // Il radar è sotto il bordo: la ListView lo costruisce solo se visibile.
    await tester.scrollUntilVisible(find.byType(RadarChart), 300,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();

    void expectFixedScale() {
      final data = tester.widget<RadarChart>(find.byType(RadarChart)).data;
      // Bordo esterno = massimo possibile, primo anello = 0: la scala non
      // si adatta più ai valori del singolo giocatore.
      expect(data.maxEntry.value, 1.0);
      expect(data.minEntry.value, 0.0);
    }

    expectFixedScale(); // Performance
    await tester.tap(find.text('Attributi FIFA'));
    await tester.pumpAndSettle();
    expectFixedScale(); // FIFA
  });

  testWidgets('tapping VOTI shows the vote trend section', (tester) async {
    await seed(tester, sixMatches());
    await pumpScreen(tester);

    await tapTab(tester, 'VOTI');

    expect(find.text('ANDAMENTO VOTI'), findsOneWidget);
  });

  testWidgets('votes tab shows relative vote card', (tester) async {
    await seed(tester, sixMatches());
    await pumpScreen(tester);

    await tapTab(tester, 'VOTI');
    await tester.scrollUntilVisible(find.text('VOTO RELATIVO'), 300,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);

    expect(find.text('VOTO RELATIVO'), findsOneWidget);
  });

  testWidgets(
      'votes tab shows the insufficient-data message when no match has a vote',
      (tester) async {
    await seed(tester, sixMatches(withVotes: false));
    await pumpScreen(tester);

    await tapTab(tester, 'VOTI');

    expect(
        find.text('DATI INSUFFICIENTI PER QUESTA CATEGORIA'), findsOneWidget);
  });

  testWidgets('compact header shows a dash when the player has no votes',
      (tester) async {
    await seed(tester, sixMatches(withVotes: false));
    await pumpScreen(tester);

    expect(find.text('6 partite · — ⭐'), findsOneWidget);
    expect(find.textContaining('0.0 ⭐'), findsNothing);
  });

  testWidgets('compact header shows games and average vote', (tester) async {
    await seed(tester, sixMatches());
    await pumpScreen(tester);

    // voti 5,6,7,5,6,7 → media 6.0
    expect(find.textContaining('6 partite'), findsOneWidget);
    expect(find.textContaining('6.0 ⭐'), findsOneWidget);
  });

  testWidgets('every tab renders its moved sections without errors',
      (tester) async {
    await seed(tester, sixMatches());
    await pumpScreen(tester);

    expect(find.text('PARTITE'), findsOneWidget);
    expect(find.text('RADAR PERFORMANCE'), findsOneWidget);

    const expectedHeaders = {
      'GOL': 'GOL PER PARTITA',
      'RISULTATI': 'WIN-RATE (ROLLING 5 PARTITE)',
      'RECORD': 'TRAGUARDI IN CARRIERA',
      'COMPAGNI': 'CHEMISTRY CON I COMPAGNI',
      'STAGIONI': 'PARTITE PER MESE',
    };
    for (final entry in expectedHeaders.entries) {
      await tapTab(tester, entry.key);
      await tester.scrollUntilVisible(find.text(entry.value), 300,
          scrollable: find
              .descendant(
                  of: find.byType(ListView), matching: find.byType(Scrollable))
              .first);
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('goals tab shows team goal share and multi-goal sections',
      (tester) async {
    await seed(tester, sixMatches());
    await pumpScreen(tester);

    await tapTab(tester, 'GOL');
    final scrollable = find
        .descendant(
            of: find.byType(ListView), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.text('QUOTA GOL SQUADRA'), 300,
        scrollable: scrollable);
    expect(find.text('QUOTA GOL SQUADRA'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('DOPPIETTE E TRIPLETTE'), 300,
        scrollable: scrollable);
    expect(find.text('DOPPIETTE E TRIPLETTE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('results tab shows goal difference and margins sections',
      (tester) async {
    await seed(tester, sixMatches());
    await pumpScreen(tester);

    await tapTab(tester, 'RISULTATI');
    final scrollable = find
        .descendant(
            of: find.byType(ListView), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.text('DIFFERENZA RETI'), 300,
        scrollable: scrollable);
    expect(find.text('DIFF. MEDIA'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('MARGINI'), 300,
        scrollable: scrollable);
    expect(find.text('MARGINI'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Di misura'), 300,
        scrollable: scrollable);
    expect(find.text('Di misura'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('records tab shows streaks and best matches; tap opens detail',
      (tester) async {
    await seed(tester, sixMatches());
    await pumpScreen(tester);

    await tapTab(tester, 'RECORD');
    final scrollable = find
        .descendant(
            of: find.byType(ListView), matching: find.byType(Scrollable))
        .first;
    expect(find.text('SERIE RECORD'), findsOneWidget);
    expect(find.text('VITTORIE'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('VOTO PIÙ ALTO'), 300,
        scrollable: scrollable);
    await tester.scrollUntilVisible(find.text('TRAGUARDI IN CARRIERA'), 300,
        scrollable: scrollable);
    expect(find.text('TRAGUARDI IN CARRIERA'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('VOTO PIÙ ALTO'), -300,
        scrollable: scrollable);
    // Porta la scheda interamente in vista: altrimenti il tocco può cadere
    // sotto l'intestazione fissa.
    await tester.ensureVisible(find.text('VOTO PIÙ ALTO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VOTO PIÙ ALTO'));
    await tester.pumpAndSettle();
    expect(find.byType(MatchDetailScreen), findsOneWidget);
  });

  testWidgets('seasons tab shows heatmap; year comparison needs two years',
      (tester) async {
    await seed(tester, sixMatches());
    await pumpScreen(tester);

    await tapTab(tester, 'STAGIONI');
    expect(find.text('MAPPA PRESENZE'), findsOneWidget);
    expect(find.text('CONFRONTO ANNI'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  MatchModel oldMatch(
          {Map<String, double>? votes = const {'p1': 4.0, 'p2': 6.0},
          String mvp = 'p1'}) =>
      MatchModel(
        id: 'old',
        date: DateTime(2025, 3, 4),
        teamA: const ['p1'],
        teamB: const ['p2'],
        scoreA: 0,
        scoreB: 3,
        votes: votes,
        goals: {'p1': 0},
        fieldLocation: '',
        mvp: mvp,
        hustlePlayer: '',
      );

  testWidgets('seasons tab shows year comparison with two years',
      (tester) async {
    await seed(tester, [...sixMatches(), oldMatch()]);
    await pumpScreen(tester);

    await tapTab(tester, 'STAGIONI');
    final scrollable = find
        .descendant(
            of: find.byType(ListView), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(find.text('CONFRONTO ANNI'), 300,
        scrollable: scrollable);
    expect(find.text('CONFRONTO ANNI'), findsOneWidget);
    expect(find.text('GIORNO DELLA SETTIMANA'), findsOneWidget);
    // 2026 vs 2025: games, voto, gol, g/p, %v salgono; mvp scende (0 vs 1).
    expect(find.text('▲'), findsNWidgets(5));
    expect(find.text('▼'), findsNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('year comparison shows a dash and no arrow without votes',
      (tester) async {
    await seed(tester, [
      ...sixMatches(),
      oldMatch(votes: null, mvp: ''),
    ]);
    await pumpScreen(tester);
    await tapTab(tester, 'STAGIONI');
    await tester.scrollUntilVisible(find.text('CONFRONTO ANNI'), 300,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);

    final dash =
        find.descendant(of: find.byType(Table), matching: find.text('—'));
    expect(dash, findsOneWidget);
    final cell = find.ancestor(of: dash, matching: find.byType(Row)).first;
    expect(find.descendant(of: cell, matching: find.textContaining('▲')),
        findsNothing);
    expect(find.descendant(of: cell, matching: find.textContaining('▼')),
        findsNothing);
    // Gli altri 4 valori salgono, mvp invariato.
    expect(find.text('▲'), findsNWidgets(4));
    expect(find.text('▼'), findsNothing);
  });

  test('formatSignedDelta signs, rounds and never shows -0.0', () {
    expect(formatSignedDelta(1.3), '+1.3');
    expect(formatSignedDelta(-0.04), '0.0');
    expect(formatSignedDelta(0.04), '0.0');
    expect(formatSignedDelta(0), '0.0');
    expect(formatSignedDelta(-0.5), '-0.5');
  });

  testWidgets('compact header uses the singular for one match', (tester) async {
    await seed(tester, [sixMatches().first]);
    await pumpScreen(tester);

    expect(find.textContaining('1 partita ·'), findsOneWidget);
    expect(find.textContaining('1 partite'), findsNothing);
  });

  testWidgets('year comparison arrows compare the rounded values',
      (tester) async {
    // 2025: 21 partite, 22 gol -> 1.048 G/P, mostrato "1.0" come il 2026.
    await seed(tester, [
      ...sixMatches(),
      for (int i = 0; i < 21; i++)
        MatchModel(
          id: 'o$i',
          date: DateTime(2025, 3, 1).add(Duration(days: i)),
          teamA: const ['p1'],
          teamB: const ['p2'],
          scoreA: 0,
          scoreB: 3,
          votes: const {'p1': 4.0, 'p2': 6.0},
          goals: {'p1': i == 0 ? 2 : 1},
          fieldLocation: '',
          mvp: '',
          hustlePlayer: '',
        ),
    ]);
    await pumpScreen(tester);
    await tapTab(tester, 'STAGIONI');
    await tester.scrollUntilVisible(find.text('CONFRONTO ANNI'), 300,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);

    // partite e gol scendono, voto e %V salgono, G/P (1.0 vs 1.0) invariato.
    expect(find.text('▲'), findsNWidgets(2));
    expect(find.text('▼'), findsNWidgets(2));
  });

  testWidgets('year comparison does not overflow on a narrow, scaled screen',
      (tester) async {
    await seed(tester, [...sixMatches(), oldMatch()]);
    await pumpScreen(tester);
    await tapTab(tester, 'STAGIONI');
    // Altri widget (header, weekday) sforano a questa scala: qui conta solo
    // la tabella confronto anni.
    final yearCardErrors = <String>[];
    final prevOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('year_comparison_card')) {
        yearCardErrors.add(details.toString());
      }
    };
    addTearDown(() => FlutterError.onError = prevOnError);
    // Si restringe lo schermo solo dopo aver lasciato la tab PANORAMICA.
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('CONFRONTO ANNI'), 300,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    expect(yearCardErrors, isEmpty);
  });

  testWidgets('best matches omit the field text when the field is deleted',
      (tester) async {
    await seed(tester, [
      for (final m in sixMatches())
        MatchModel(
          id: m.id,
          date: m.date,
          teamA: m.teamA,
          teamB: m.teamB,
          scoreA: m.scoreA,
          scoreB: m.scoreB,
          votes: m.votes,
          goals: m.goals,
          fieldLocation: 'ghost-field-id',
          mvp: '',
          hustlePlayer: '',
        ),
    ]);
    await pumpScreen(tester);
    await tapTab(tester, 'RECORD');
    await tester.scrollUntilVisible(find.text('VOTO PIÙ ALTO'), 300,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    expect(find.text('ghost-field-id'), findsNothing);
  });

  group('heatmap with pinned today', () {
    bool selected(WidgetTester tester, String year) => tester
        .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, year))
        .selected;

    Future<void> open(WidgetTester tester, DateTime today,
        {bool twoYears = true}) async {
      await seed(tester, [
        ...sixMatches(),
        if (twoYears) oldMatch(),
      ]);
      await pumpScreen(tester, today: today);
      await tapTab(tester, 'STAGIONI');
    }

    testWidgets('defaults to the year of today when active', (tester) async {
      await open(tester, DateTime(2025, 6, 1));
      expect(selected(tester, '2025'), isTrue);
      expect(selected(tester, '2026'), isFalse);
    });

    testWidgets('defaults to the latest year when today is not active',
        (tester) async {
      await open(tester, DateTime(2030, 6, 1));
      expect(selected(tester, '2026'), isTrue);
      expect(selected(tester, '2025'), isFalse);
    });

    Finder heatmapScroll() => find.byKey(const Key('activity_heatmap_scroll'));

    /// Il offset deve portare la colonna della settimana corrente nel viewport.
    void expectWeekInViewport(WidgetTester tester, DateTime today) {
      final sv = tester.widget<SingleChildScrollView>(heatmapScroll());
      final c = sv.controller!;
      final days = heatmapDays(today.year);
      final week =
          days.indexOf(DateTime.utc(today.year, today.month, today.day)) ~/ 7;
      const step = 12.0 + 3.0;
      final start = week * step, end = (week + 1) * step;
      expect(c.offset, lessThanOrEqualTo(start));
      expect(
          c.offset + c.position.viewportDimension, greaterThanOrEqualTo(end));
    }

    testWidgets('keeps the current week visible for a late-year today',
        (tester) async {
      final today = DateTime(2026, 12, 20);
      await open(tester, today, twoYears: false);
      expect(
          tester
              .widget<SingleChildScrollView>(heatmapScroll())
              .controller!
              .offset,
          greaterThan(0));
      expectWeekInViewport(tester, today);
    });

    testWidgets('keeps the current week visible for a mid-year today',
        (tester) async {
      final today = DateTime(2026, 4, 15);
      await open(tester, today, twoYears: false);
      expectWeekInViewport(tester, today);
    });
  });
}
