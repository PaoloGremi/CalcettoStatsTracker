import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/training.dart';
import '../repositories/training_repository.dart';
import '../training_validation.dart';

/// Crea o aggiorna un allenamento: lo normalizza, lo valida e solo se è
/// valido lo passa al repository.
class SaveTraining {
  SaveTraining(this._repository, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final TrainingRepository _repository;
  final DateTime Function() _clock;

  Future<Result<Training>> call(Training t) async {
    final normalized = t.normalized();
    final error = validateTraining(normalized, today: _clock());
    if (error != null) return Result.failure(ValidationFailure(error));
    return _repository.saveTraining(normalized);
  }
}
