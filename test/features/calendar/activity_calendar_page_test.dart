import 'package:calcetto_tracker/core/error/result.dart';
import 'package:calcetto_tracker/features/calendar/presentation/activity_calendar_page.dart';
import 'package:calcetto_tracker/features/trainings/domain/entities/training.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/delete_training.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/get_all_trainings.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/save_training.dart';
import 'package:calcetto_tracker/features/trainings/presentation/controllers/trainings_controller.dart';
import 'package:calcetto_tracker/models/field_model.dart';
import 'package:calcetto_tracker/models/match_model.dart';
import 'package:calcetto_tracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAllTrainings extends Mock implements GetAllTrainings {}

class MockSaveTraining extends Mock implements SaveTraining {}

class MockDeleteTraining extends Mock implements DeleteTraining {}

MatchModel _match(String id, DateTime date) => MatchModel(
      id: id,
      date: date,
      teamA: const ['me'],
      teamB: const ['x'],
      scoreA: 5,
      scoreB: 3,
      fieldLocation: 'f1',
      mvp: '',
      hustlePlayer: '',
    );

final _run = Training(
  id: 'r',
  date: DateTime(2026, 10, 10),
  type: TrainingType.running,
  distanceKm: 5,
  runSeconds: 1500,
);

void main() {
  late MockGetAllTrainings getAll;
  late TrainingsController controller;

  setUpAll(() => initializeDateFormatting('it_IT', null));

  setUp(() {
    getAll = MockGetAllTrainings();
    controller = TrainingsController(
      getAllTrainings: getAll,
      saveTraining: MockSaveTraining(),
      deleteTraining: MockDeleteTraining(),
      clock: () => DateTime(2026, 10, 24),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    // Schermo da telefono: a 800px di larghezza le celle quadrate sono così
    // grandi che parte del mese finisce fuori vista.
    if (tester.view.physicalSize == const Size(2400, 1800)) {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    when(() => getAll()).thenAnswer((_) async => Result.success([_run]));
    await controller.load();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme,
      home: ActivityCalendarPage(
        trainings: controller,
        playerId: 'me',
        matches: [
          _match('today', DateTime(2026, 10, 24, 21)),
          _match('sep', DateTime(2026, 9, 15, 20)),
          _match('old', DateTime(2025, 3, 2, 20)),
        ],
        fieldLookup: (id) => id == 'f1'
            ? FieldModel(id: 'f1', name: 'Campo Nord', address: '')
            : null,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('opens scrolled to the current month with today selected',
      (tester) async {
    await pump(tester);

    expect(find.text('2026'), findsOneWidget);
    expect(find.text('OTTOBRE').hitTestable(), findsOneWidget);
    expect(find.text('1 partita · 1 allenamento'), findsOneWidget);
    expect(find.text('24 OTT 2026'), findsOneWidget);
    expect(find.textContaining('Campo Nord'), findsOneWidget);
  });

  testWidgets('tapping a day shows its entries', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('day_2026-10-10')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Corsa'), findsOneWidget);
    expect(find.textContaining('Campo Nord'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('day_2026-10-11')));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna attività in questo giorno'), findsOneWidget);
  });

  testWidgets('months scroll vertically and Oggi comes back',
      (tester) async {
    await pump(tester);

    // Scorrendo verso l'alto si arriva a settembre.
    final sep15 = find.byKey(const ValueKey('day_2026-09-15'));
    await tester.scrollUntilVisible(sep15, -200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(sep15);
    await tester.pumpAndSettle();
    expect(find.text('15 SET 2026'), findsOneWidget);
    expect(find.textContaining('Campo Nord'), findsOneWidget);

    // Scorro fino in fondo all'anno, poi Oggi riporta a ottobre e a oggi.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('OTTOBRE').hitTestable(), findsNothing);

    await tester.tap(find.text('OGGI'));
    await tester.pumpAndSettle();
    expect(find.text('OTTOBRE').hitTestable(), findsOneWidget);
    expect(find.text('24 OTT 2026'), findsOneWidget);
  });

  testWidgets('the year menu switches to another year', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('Scegli anno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2025').last);
    await tester.pumpAndSettle();

    expect(find.text('2025'), findsOneWidget);
    expect(find.text('GENNAIO').hitTestable(), findsOneWidget);

    final mar2 = find.byKey(const ValueKey('day_2025-03-02'));
    await tester.scrollUntilVisible(mar2, 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(mar2);
    await tester.pumpAndSettle();
    expect(find.text('2 MAR 2025'), findsOneWidget);
    expect(find.textContaining('Campo Nord'), findsOneWidget);
  });

  testWidgets('updates when the trainings controller reloads',
      (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('day_2026-10-10')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Corsa'), findsOneWidget);

    when(() => getAll()).thenAnswer((_) async => Result.success(const []));
    await controller.load();
    await tester.pumpAndSettle();

    expect(find.textContaining('Corsa'), findsNothing);
    // Ottobre ora ha solo la partita, come settembre.
    expect(find.text('1 partita'), findsNWidgets(2));
  });

  testWidgets('fits a small screen with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester);

    expect(tester.takeException(), isNull);
  });
}
