import 'package:calcetto_tracker/core/error/failure.dart';
import 'package:calcetto_tracker/core/error/result.dart';
import 'package:calcetto_tracker/features/trainings/domain/entities/training.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/delete_training.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/get_all_trainings.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/save_training.dart';
import 'package:calcetto_tracker/features/trainings/presentation/controllers/trainings_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAllTrainings extends Mock implements GetAllTrainings {}

class MockSaveTraining extends Mock implements SaveTraining {}

class MockDeleteTraining extends Mock implements DeleteTraining {}

final _run = Training(
  id: 'r',
  date: DateTime(2026, 10, 20),
  type: TrainingType.running,
  distanceKm: 5,
  runSeconds: 1500,
);

void main() {
  late MockGetAllTrainings getAll;
  late MockSaveTraining save;
  late MockDeleteTraining delete;
  late TrainingsController controller;

  setUpAll(() => registerFallbackValue(_run));

  setUp(() {
    getAll = MockGetAllTrainings();
    save = MockSaveTraining();
    delete = MockDeleteTraining();
    controller = TrainingsController(
      getAllTrainings: getAll,
      saveTraining: save,
      deleteTraining: delete,
      clock: () => DateTime(2026, 10, 21),
    );
    when(() => getAll()).thenAnswer((_) async => Result.success([_run]));
  });

  test('load exposes trainings and stats', () async {
    expect(controller.isLoading, isTrue);

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.trainings, [_run]);
    expect(controller.stats.longestRunKm, 5);
    expect(controller.stats.thisWeekCount, 1);
  });

  test('stats follow the clock across a week boundary', () async {
    var now = DateTime(2026, 10, 21);
    controller = TrainingsController(
      getAllTrainings: getAll,
      saveTraining: save,
      deleteTraining: delete,
      clock: () => now,
    );
    await controller.load();
    expect(controller.stats.thisWeekCount, 1);

    now = DateTime(2026, 10, 27); // martedì della settimana dopo
    expect(controller.stats.thisWeekCount, 0);
    expect(controller.stats.currentWeekStreak, 1);
  });

  test('load failure sets error', () async {
    when(() => getAll())
        .thenAnswer((_) async => Result.failure(const CacheFailure('boom')));

    await controller.load();

    expect(controller.error, 'boom');
    expect(controller.isLoading, isFalse);
  });

  test('save returns null and reloads on success', () async {
    when(() => save(any())).thenAnswer((_) async => Result.success(_run));

    final message = await controller.save(_run);

    expect(message, isNull);
    verify(() => getAll()).called(1);
  });

  test('save returns the validation message on failure', () async {
    when(() => save(any())).thenAnswer((_) async =>
        Result.failure(const ValidationFailure('Distanza mancante')));

    final message = await controller.save(_run);

    expect(message, 'Distanza mancante');
    expect(controller.error, isNull);
    verifyNever(() => getAll());
  });

  test('remove failure sets error', () async {
    when(() => delete(any()))
        .thenAnswer((_) async => Result.failure(const CacheFailure('no')));

    final ok = await controller.remove('r');

    expect(ok, isFalse);
    expect(controller.error, 'no');
  });

  test('remove success reloads', () async {
    when(() => delete(any())).thenAnswer((_) async => Result.success(null));

    expect(await controller.remove('r'), isTrue);
    verify(() => getAll()).called(1);
  });
}
