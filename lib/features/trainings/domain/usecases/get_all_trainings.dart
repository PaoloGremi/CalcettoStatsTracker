import '../../../../core/error/result.dart';
import '../entities/training.dart';
import '../repositories/training_repository.dart';

/// Tutti gli allenamenti, dal più recente.
class GetAllTrainings {
  const GetAllTrainings(this._repository);

  final TrainingRepository _repository;

  Future<Result<List<Training>>> call() => _repository.getAllTrainings();
}
