import 'dart:io';

import 'package:calcetto_tracker/data/hive_boxes.dart';
import 'package:calcetto_tracker/models/field_model.dart';
import 'package:calcetto_tracker/models/match_model.dart';
import 'package:calcetto_tracker/models/player_model.dart';
import 'package:calcetto_tracker/screens/player_stats_screen.dart';
import 'package:calcetto_tracker/services/data_service.dart';
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

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<DataService>.value(
        value: dataService,
        child: PlayerStatsScreen(player: mario),
      ),
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
    final tabs = tester.widgetList<Tab>(find.byType(Tab)).toList();
    expect(tabs.map((t) => t.text).toList(), labels);
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
        .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
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
        .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
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
}
