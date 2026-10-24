import 'package:calcetto_tracker/core/error/failure.dart';
import 'package:calcetto_tracker/core/error/result.dart';
import 'package:calcetto_tracker/features/trainings/domain/entities/training.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/delete_training.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/get_all_trainings.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/save_training.dart';
import 'package:calcetto_tracker/features/trainings/presentation/controllers/trainings_controller.dart';
import 'package:calcetto_tracker/features/trainings/presentation/pages/training_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockGetAllTrainings extends Mock implements GetAllTrainings {}

class MockSaveTraining extends Mock implements SaveTraining {}

class MockDeleteTraining extends Mock implements DeleteTraining {}

final _mixed = Training(
  id: 'm',
  date: DateTime(2026, 10, 20),
  type: TrainingType.mixed,
  durationMinutes: 60,
  distanceKm: 5.2,
  runSeconds: 1530,
  categories: const {TechnicalCategory.shots},
);

const _runTime = Key('run_time_field');
const _distance = Key('distance_field');
const _duration = Key('duration_field');
const _saveButton = Key('save_button');

void main() {
  late MockGetAllTrainings getAll;
  late MockSaveTraining save;
  late MockDeleteTraining delete;
  late TrainingsController controller;

  setUpAll(() async {
    registerFallbackValue(_mixed);
    await initializeDateFormatting('it_IT', null);
  });

  setUp(() {
    getAll = MockGetAllTrainings();
    save = MockSaveTraining();
    delete = MockDeleteTraining();
    controller = TrainingsController(
        getAllTrainings: getAll, saveTraining: save, deleteTraining: delete);
    when(() => getAll()).thenAnswer((_) async => Result.success(const []));
  });

  Future<void> pump(WidgetTester tester, {Training? initial}) async {
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<TrainingsController>.value(
        value: controller,
        child: TrainingFormPage(initial: initial),
      ),
    ));
  }

  testWidgets('running shows only run fields', (tester) async {
    await pump(tester);

    expect(find.byKey(_runTime), findsOneWidget);
    expect(find.byKey(_distance), findsOneWidget);
    expect(find.byKey(_duration), findsNothing);
    expect(find.text('Tiri'), findsNothing);
  });

  testWidgets('technical shows duration and categories only', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Tecnico'));
    await tester.pump();

    expect(find.byKey(_runTime), findsNothing);
    expect(find.byKey(_distance), findsNothing);
    expect(find.byKey(_duration), findsOneWidget);
    expect(find.text('Tiri'), findsOneWidget);
  });

  testWidgets('walking shows distance and time under a walking title',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Camminata'));
    await tester.pump();

    expect(find.byKey(_runTime), findsOneWidget);
    expect(find.byKey(_distance), findsOneWidget);
    expect(find.byKey(_duration), findsNothing);
    expect(find.text('CAMMINATA'), findsOneWidget);
    expect(find.text('Tempo'), findsOneWidget);
    expect(find.text('CORSA'), findsNothing);
  });

  testWidgets('saves a walking training', (tester) async {
    when(() => save(any())).thenAnswer((_) async => Result.success(_mixed));
    await pump(tester);
    await tester.tap(find.text('Camminata'));
    await tester.pump();
    await tester.enterText(find.byKey(_runTime), '46:00');
    await tester.enterText(find.byKey(_distance), '4');
    await tester.ensureVisible(find.byKey(_saveButton));
    await tester.tap(find.byKey(_saveButton));
    await tester.pump();

    final saved = verify(() => save(captureAny())).captured.single as Training;
    expect(saved.type, TrainingType.walking);
    expect(saved.runSeconds, 2760);
    expect(saved.distanceKm, 4);
  });

  testWidgets('type selector fits at 320 px with text scale 1.3',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('swimming shows only the duration', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Nuoto'));
    await tester.pump();

    expect(find.byKey(_runTime), findsNothing);
    expect(find.byKey(_distance), findsNothing);
    expect(find.byKey(_duration), findsOneWidget);
    expect(find.text('Tiri'), findsNothing);
    expect(find.text('NUOTO'), findsOneWidget);
  });

  testWidgets('saves a swimming training', (tester) async {
    when(() => save(any())).thenAnswer((_) async => Result.success(_mixed));
    await pump(tester);
    await tester.tap(find.text('Nuoto'));
    await tester.pump();
    await tester.enterText(find.byKey(_duration), '45');
    await tester.ensureVisible(find.byKey(_saveButton));
    await tester.tap(find.byKey(_saveButton));
    await tester.pump();

    final saved = verify(() => save(captureAny())).captured.single as Training;
    expect(saved.type, TrainingType.swimming);
    expect(saved.durationMinutes, 45);
  });

  testWidgets('mixed shows both', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Misto'));
    await tester.pump();

    expect(find.byKey(_runTime), findsOneWidget);
    expect(find.byKey(_duration), findsOneWidget);
    expect(find.text('Forza'), findsOneWidget);
  });

  testWidgets('unparseable time shows an error and does not save',
      (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(_runTime), 'abc');
    await tester.enterText(find.byKey(_distance), '5');
    await tester.ensureVisible(find.byKey(_saveButton));
    await tester.tap(find.byKey(_saveButton));
    await tester.pump();

    expect(find.text('Formato tempo non valido'), findsOneWidget);
    verifyNever(() => save(any()));
  });

  testWidgets('saves the parsed values', (tester) async {
    when(() => save(any())).thenAnswer((_) async => Result.success(_mixed));
    await pump(tester);
    await tester.enterText(find.byKey(_runTime), '25:30');
    await tester.enterText(find.byKey(_distance), '5,2');
    await tester.ensureVisible(find.byKey(_saveButton));
    await tester.tap(find.byKey(_saveButton));
    await tester.pump();

    final saved = verify(() => save(captureAny())).captured.single as Training;
    expect(saved.type, TrainingType.running);
    expect(saved.runSeconds, 1530);
    expect(saved.distanceKm, 5.2);
  });

  testWidgets('validation message from controller appears in a SnackBar',
      (tester) async {
    when(() => save(any())).thenAnswer((_) async => Result.failure(
        const ValidationFailure('Scegli almeno una categoria tecnica')));
    await pump(tester);
    await tester.tap(find.text('Tecnico'));
    await tester.pump();
    await tester.enterText(find.byKey(_duration), '60');
    await tester.ensureVisible(find.byKey(_saveButton));
    await tester.tap(find.byKey(_saveButton));
    await tester.pump();

    expect(find.descendant(
            of: find.byType(SnackBar),
            matching: find.text('Scegli almeno una categoria tecnica')),
        findsOneWidget);
  });

  testWidgets('editing prefills fields and delete asks for confirmation',
      (tester) async {
    when(() => delete(any())).thenAnswer((_) async => Result.success(null));
    await pump(tester, initial: _mixed);

    expect(find.text('25:30'), findsOneWidget);
    expect(find.text('5,2'), findsOneWidget);
    expect(find.text('60'), findsOneWidget);

    await tester.tap(find.byTooltip('Elimina'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare questo allenamento?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Elimina'));
    await tester.pumpAndSettle();
    verify(() => delete('m')).called(1);
  });
}
