import '../../../../core/error/result.dart';
import '../entities/player.dart';
import '../repositories/player_repository.dart';

/// Recupera tutti i giocatori registrati.
class GetAllPlayers {
  const GetAllPlayers(this._repository);

  final PlayerRepository _repository;

  Future<Result<List<Player>>> call() => _repository.getAllPlayers();
}
