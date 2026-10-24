import '../../../../core/error/result.dart';
import '../entities/training.dart';

/// Contratto verso il layer dati per gli allenamenti.
abstract class TrainingRepository {
  /// Tutti gli allenamenti, dal più recente.
  Future<Result<List<Training>>> getAllTrainings();

  /// Crea o aggiorna (per `id`).
  Future<Result<Training>> saveTraining(Training t);

  Future<Result<void>> deleteTraining(String id);
}
