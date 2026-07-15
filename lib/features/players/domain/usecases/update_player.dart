import '../../../../core/error/result.dart';
import '../entities/player.dart';
import '../repositories/player_repository.dart';

/// Aggiorna un giocatore esistente.
class UpdatePlayer {
  const UpdatePlayer(this._repository);

  final PlayerRepository _repository;

  Future<Result<Player>> call(Player player) =>
      _repository.updatePlayer(player);
}
