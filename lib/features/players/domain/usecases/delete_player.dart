import '../../../../core/error/result.dart';
import '../repositories/player_repository.dart';

/// Elimina un giocatore. L'implementazione del repository si occupa anche
/// di ripulire i riferimenti al giocatore nelle partite esistenti
/// (formazioni/voti/gol).
class DeletePlayer {
  const DeletePlayer(this._repository);

  final PlayerRepository _repository;

  Future<Result<void>> call(String id) => _repository.deletePlayer(id);
}
