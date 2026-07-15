import '../../../../core/error/result.dart';
import '../entities/player.dart';
import '../repositories/player_repository.dart';

/// Aggiunge un nuovo giocatore.
class AddPlayer {
  const AddPlayer(this._repository);

  final PlayerRepository _repository;

  Future<Result<Player>> call({
    required String name,
    required String icon,
    required String role,
    String? imagePath,
  }) {
    return _repository.addPlayer(
      name: name,
      icon: icon,
      role: role,
      imagePath: imagePath,
    );
  }
}
