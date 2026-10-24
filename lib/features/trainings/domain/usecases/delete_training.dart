import '../../../../core/error/result.dart';
import '../repositories/training_repository.dart';

/// Elimina un allenamento.
class DeleteTraining {
  const DeleteTraining(this._repository);

  final TrainingRepository _repository;

  Future<Result<void>> call(String id) => _repository.deleteTraining(id);
}
