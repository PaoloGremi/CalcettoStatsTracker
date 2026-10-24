import 'package:calcetto_tracker/core/error/failure.dart';
import 'package:calcetto_tracker/features/trainings/domain/entities/training.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/delete_training.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/get_all_trainings.dart';
import 'package:calcetto_tracker/features/trainings/domain/usecases/save_training.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_training_repository.dart';

final _mixed = Training(
  id: 'm',
  date: DateTime(2026, 10, 20),
  type: TrainingType.mixed,
  durationMinutes: 60,
  distanceKm: 5,
  runSeconds: 1500,
  categories: const {TechnicalCategory.shots},
);

void main() {
  late FakeTrainingRepository repo;
  late SaveTraining save;

  setUp(() {
    repo = FakeTrainingRepository();
    save = SaveTraining(repo, clock: () => DateTime(2026, 10, 24));
  });

  test('get all forwards the repository result', () async {
    repo.trainings.add(_mixed);

    final result = await GetAllTrainings(repo)();

    expect(result.fold((v) => v, (_) => null), [_mixed]);
  });

  test('save normalizes before persisting', () async {
    final result = await save(_mixed.copyWith(type: TrainingType.running));

    expect(result.isSuccess, isTrue);
    expect(repo.trainings.single.categories, isEmpty);
    expect(repo.trainings.single.durationMinutes, isNull);
  });

  test('save returns ValidationFailure and does not hit the repository',
      () async {
    final result = await save(_mixed.copyWith(categories: const {}));

    final failure = result.fold((_) => null, (f) => f);
    expect(failure, isA<ValidationFailure>());
    expect(failure!.message, 'Scegli almeno una categoria tecnica');
    expect(repo.saveCalls, 0);
  });

  test('save rejects a future date using the injected clock', () async {
    final result = await save(_mixed.copyWith(date: DateTime(2026, 10, 25)));

    expect(result.fold((_) => null, (f) => f.message),
        'La data non può essere nel futuro');
  });

  test('delete forwards the id', () async {
    final result = await DeleteTraining(repo)('m');

    expect(result.isSuccess, isTrue);
    expect(repo.lastDeletedId, 'm');
  });

  test('repository failure is passed through', () async {
    repo.shouldFail = true;

    final result = await save(_mixed);

    expect(result.fold((_) => null, (f) => f), isA<CacheFailure>());
  });
}
