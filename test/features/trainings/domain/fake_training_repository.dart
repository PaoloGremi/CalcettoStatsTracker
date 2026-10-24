import 'package:calcetto_tracker/core/error/failure.dart';
import 'package:calcetto_tracker/core/error/result.dart';
import 'package:calcetto_tracker/features/trainings/domain/entities/training.dart';
import 'package:calcetto_tracker/features/trainings/domain/repositories/training_repository.dart';

/// Fake in-memory di [TrainingRepository] per testare gli usecase senza Hive.
class FakeTrainingRepository implements TrainingRepository {
  final List<Training> trainings = [];
  bool shouldFail = false;
  Failure failureToReturn = const CacheFailure('errore simulato');

  int saveCalls = 0;
  int deleteCalls = 0;
  String? lastDeletedId;

  @override
  Future<Result<List<Training>>> getAllTrainings() async {
    if (shouldFail) return Result.failure(failureToReturn);
    return Result.success(List.of(trainings));
  }

  @override
  Future<Result<Training>> saveTraining(Training t) async {
    saveCalls++;
    if (shouldFail) return Result.failure(failureToReturn);
    trainings
      ..removeWhere((e) => e.id == t.id)
      ..add(t);
    return Result.success(t);
  }

  @override
  Future<Result<void>> deleteTraining(String id) async {
    deleteCalls++;
    lastDeletedId = id;
    if (shouldFail) return Result.failure(failureToReturn);
    trainings.removeWhere((e) => e.id == id);
    return Result.success(null);
  }
}
