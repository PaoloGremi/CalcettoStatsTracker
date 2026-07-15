import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../services/data_service.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/player_local_datasource.dart';
import '../mappers/player_mapper.dart';

/// Implementazione Hive del [PlayerRepository].
///
/// Le mutazioni (add/update/delete) delegano a [DataService] invece di
/// scrivere direttamente sul box Hive: [DataService] resta l'unica fonte
/// di `notifyListeners()` per i giocatori, quindi gli screen non ancora
/// migrati a questa feature (che leggono tramite `Provider<DataService>`)
/// continuano a vedere gli aggiornamenti fatti da qui. Duplicare la
/// scrittura Hive qui romperebbe quella reattività in modo silenzioso.
/// `deletePlayer` inoltre riusa la pulizia referenziale di [DataService]
/// (rimozione del giocatore da formazioni/voti/gol nelle partite esistenti)
/// invece di reimplementarla.
class PlayerRepositoryImpl implements PlayerRepository {
  PlayerRepositoryImpl({
    required PlayerLocalDataSource localDataSource,
    required DataService dataService,
    PlayerMapper mapper = const PlayerMapper(),
  })  : _localDataSource = localDataSource,
        _dataService = dataService,
        _mapper = mapper;

  final PlayerLocalDataSource _localDataSource;
  final DataService _dataService;
  final PlayerMapper _mapper;

  @override
  Future<Result<List<Player>>> getAllPlayers() async {
    try {
      final models = _localDataSource.getAll();
      return Result.success(models.map(_mapper.toEntity).toList());
    } catch (e) {
      return Result.failure(
          CacheFailure('Impossibile leggere i giocatori: $e'));
    }
  }

  @override
  Future<Result<Player>> addPlayer({
    required String name,
    required String icon,
    required String role,
    String? imagePath,
  }) async {
    try {
      final model = await _dataService.addPlayer(
        name,
        icon,
        role: role,
        imagePath: imagePath,
      );
      return Result.success(_mapper.toEntity(model));
    } catch (e) {
      return Result.failure(
          CacheFailure('Impossibile aggiungere il giocatore: $e'));
    }
  }

  @override
  Future<Result<Player>> updatePlayer(Player player) async {
    try {
      await _dataService.updatePlayer(_mapper.toModel(player));
      return Result.success(player);
    } catch (e) {
      return Result.failure(
          CacheFailure('Impossibile aggiornare il giocatore: $e'));
    }
  }

  @override
  Future<Result<void>> deletePlayer(String id) async {
    try {
      await _dataService.deletePlayer(id);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
          CacheFailure('Impossibile eliminare il giocatore: $e'));
    }
  }
}
