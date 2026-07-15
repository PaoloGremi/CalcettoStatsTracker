import 'package:calcetto_tracker/core/error/failure.dart';
import 'package:calcetto_tracker/core/error/result.dart';
import 'package:calcetto_tracker/features/players/domain/entities/player.dart';
import 'package:calcetto_tracker/features/players/domain/repositories/player_repository.dart';

/// Fake in-memory di [PlayerRepository] per testare gli usecase senza Hive.
/// Non un mock: espone liste semplici e un flag per simulare un fallimento,
/// coerente col fatto che gli usecase Players sono thin wrapper 1:1 sul
/// repository (un fake resta leggibile, non serve mocktail qui).
class FakePlayerRepository implements PlayerRepository {
  final List<Player> players = [];
  bool shouldFail = false;
  Failure failureToReturn = const CacheFailure('errore simulato');

  int addCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  Future<Result<List<Player>>> getAllPlayers() async {
    if (shouldFail) return Result.failure(failureToReturn);
    return Result.success(List.of(players));
  }

  @override
  Future<Result<Player>> addPlayer({
    required String name,
    required String icon,
    required String role,
    String? imagePath,
  }) async {
    addCalls++;
    if (shouldFail) return Result.failure(failureToReturn);
    final player = Player(
      id: 'id-${players.length}',
      name: name,
      icon: icon,
      role: role,
      imagePath: imagePath,
    );
    players.add(player);
    return Result.success(player);
  }

  @override
  Future<Result<Player>> updatePlayer(Player player) async {
    updateCalls++;
    if (shouldFail) return Result.failure(failureToReturn);
    final index = players.indexWhere((p) => p.id == player.id);
    if (index != -1) players[index] = player;
    return Result.success(player);
  }

  @override
  Future<Result<void>> deletePlayer(String id) async {
    deleteCalls++;
    if (shouldFail) return Result.failure(failureToReturn);
    players.removeWhere((p) => p.id == id);
    return Result.success(null);
  }
}
