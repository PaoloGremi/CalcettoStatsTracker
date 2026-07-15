import '../../../../core/error/result.dart';
import '../entities/player.dart';

/// Contratto verso il layer dati per la feature Players. La UI e gli
/// usecase dipendono solo da questa interfaccia, mai dall'implementazione
/// concreta (Hive) — così sono facilmente testabili con un fake.
abstract class PlayerRepository {
  Future<Result<List<Player>>> getAllPlayers();

  Future<Result<Player>> addPlayer({
    required String name,
    required String icon,
    required String role,
    String? imagePath,
  });

  Future<Result<Player>> updatePlayer(Player player);

  Future<Result<void>> deletePlayer(String id);
}
