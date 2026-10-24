import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/training.dart';
import '../../domain/repositories/training_repository.dart';
import '../datasources/training_local_datasource.dart';
import '../mappers/training_mapper.dart';

/// Implementazione Hive del [TrainingRepository]. A differenza dei giocatori
/// scrive direttamente sul box: gli allenamenti non hanno riferimenti a
/// giocatori o partite, quindi non serve passare da `DataService`.
class TrainingRepositoryImpl implements TrainingRepository {
  TrainingRepositoryImpl({
    required TrainingLocalDataSource localDataSource,
    TrainingMapper mapper = const TrainingMapper(),
  })  : _localDataSource = localDataSource,
        _mapper = mapper;

  final TrainingLocalDataSource _localDataSource;
  final TrainingMapper _mapper;

  @override
  Future<Result<List<Training>>> getAllTrainings() async {
    try {
      final list = _localDataSource.getAll().map(_mapper.toEntity).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return Result.success(list);
    } catch (e) {
      return Result.failure(
          CacheFailure('Impossibile leggere gli allenamenti: $e'));
    }
  }

  @override
  Future<Result<Training>> saveTraining(Training t) async {
    try {
      await _localDataSource.put(_mapper.toModel(t));
      return Result.success(t);
    } catch (e) {
      return Result.failure(
          CacheFailure('Impossibile salvare gli allenamenti: $e'));
    }
  }

  @override
  Future<Result<void>> deleteTraining(String id) async {
    try {
      await _localDataSource.delete(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
          CacheFailure('Impossibile eliminare gli allenamenti: $e'));
    }
  }
}
