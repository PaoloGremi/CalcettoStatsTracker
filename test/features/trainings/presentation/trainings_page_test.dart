import 'package:calcetto_tracker/core/error/result.dart';
import 'package:calcetto_tracker/features/trainings/domain/entities/training.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/delete_training.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/get_all_trainings.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/save_training.dart';
import 'package:calcetto_tracker/features/trainings/presentation/controllers/trainings_controller.dart';
import 'package:calcetto_tracker/features/trainings/presentation/pages/trainings_page.dart';
import 'package:calcetto_tracker/theme/app_theme.dart';
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
  distanceKm: 5,
  runSeconds: 1500,
);

final _mixed = Training(
  id: 'm',
  date: DateTime(2026, 10, 10),
  type: TrainingType.mixed,
  durationMinutes: 60,
  distanceKm: 5.2,
  runSeconds: 1530,
  categories: const {TechnicalCategory.shots},
);

final _listScrollable = find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

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

  tearDown(() => AppTheme.isLight = false);

  Future<void> pump(WidgetTester tester, List<Training> data) async {
    when(() => getAll()).thenAnswer((_) async => Result.success(data));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme,
      home: TrainingsPage(controller: controller),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows empty state', (tester) async {
    await pump(tester, const []);

    expect(find.text('Nessun allenamento registrato'), findsOneWidget);
    expect(find.text('Aggiungi allenamento'), findsOneWidget);
  });

  testWidgets('shows records, chart message with one run, and history',
      (tester) async {
    await pump(tester, [_run]);

    expect(find.text('5:00/km'), findsOneWidget);
    expect(find.text('5 km'), findsOneWidget);
    expect(find.text('Servono almeno 2 corse per vedere l\'andamento'),
        findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ieri · Corsa'), 200,
        scrollable: _listScrollable);
    expect(find.text('5 km · 25:00 · 5:00/km'), findsOneWidget);
  });

  testWidgets('history row subtitle for a mixed training', (tester) async {
    await pump(tester, [_run, _mixed]);

    await tester.scrollUntilVisible(
        find.text('5,2 km · 25:30 · 4:54/km · 60 min · Tiri'), 200,
        scrollable: _listScrollable);
    expect(find.text('5,2 km · 25:30 · 4:54/km · 60 min · Tiri'),
        findsOneWidget);
  });

  testWidgets('renders in light theme without exceptions', (tester) async {
    AppTheme.isLight = true;
    await pump(tester, [_run, _mixed]);

    expect(tester.takeException(), isNull);
    expect(find.text('Allenamenti'), findsOneWidget);
  });
}
