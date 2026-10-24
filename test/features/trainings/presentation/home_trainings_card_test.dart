import 'package:calcetto_tracker/core/error/result.dart';
import 'package:calcetto_tracker/features/trainings/domain/entities/training.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/delete_training.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/get_all_trainings.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/save_training.dart';
import 'package:calcetto_tracker/features/trainings/presentation/controllers/trainings_controller.dart';
import 'package:calcetto_tracker/features/trainings/presentation/widgets/home_trainings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAllTrainings extends Mock implements GetAllTrainings {}

class MockSaveTraining extends Mock implements SaveTraining {}

class MockDeleteTraining extends Mock implements DeleteTraining {}

final _run = Training(
  id: 'r',
  date: DateTime(2026, 10, 23),
  type: TrainingType.running,
  distanceKm: 5.2,
  runSeconds: 1624, // 312.3 s/km → 5:12
);

final _tech = Training(
  id: 't',
  date: DateTime(2026, 10, 20),
  type: TrainingType.technical,
  durationMinutes: 60,
  categories: const {TechnicalCategory.shots},
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

  Future<void> pump(WidgetTester tester, List<Training> data) async {
    when(() => getAll()).thenAnswer((_) async => Result.success(data));
    await controller.load();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [HomeTrainingsCard(controller: controller)]),
      ),
    ));
  }

  testWidgets('empty state text', (tester) async {
    await pump(tester, const []);

    expect(find.text('Registra il tuo primo allenamento'), findsOneWidget);
  });

  testWidgets('latest training summary and weekly count', (tester) async {
    await pump(tester, [_run, _tech]);

    expect(find.text('Ieri · Corsa 5,2 km · 5:12/km'), findsOneWidget);
    expect(find.text('2 questa settimana'), findsOneWidget);
  });

  testWidgets('technical latest shows minutes', (tester) async {
    await pump(tester, [_tech]);

    expect(find.text('20 ott 2026 · Tecnico 60 min'), findsOneWidget);
  });

  testWidgets('does not overflow at 320x568 with textScaler 1.3',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester, [_run, _tech]);

    expect(tester.takeException(), isNull);
  });
}
