import 'package:calcetto_tracker/features/players/domain/entities/player.dart';
import 'package:calcetto_tracker/features/players/domain/usecases/add_player.dart';
import 'package:calcetto_tracker/features/players/domain/usecases/delete_player.dart';
import 'package:calcetto_tracker/features/players/domain/usecases/get_all_players.dart';
import 'package:calcetto_tracker/features/players/domain/usecases/update_player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_player_repository.dart';

void main() {
  late FakePlayerRepository repository;

  setUp(() {
    repository = FakePlayerRepository();
  });

  group('GetAllPlayers', () {
    test('returns the players currently in the repository', () async {
      repository.players.add(
        const Player(id: 'p1', name: 'Mario', role: 'A', icon: 'star'),
      );
      final usecase = GetAllPlayers(repository);

      final result = await usecase();

      expect(result.isSuccess, isTrue);
      expect(result.fold((players) => players.length, (_) => -1), 1);
    });

    test('propagates a failure from the repository', () async {
      repository.shouldFail = true;
      final usecase = GetAllPlayers(repository);

      final result = await usecase();

      expect(result.isFailure, isTrue);
    });
  });

  group('AddPlayer', () {
    test('forwards all fields to the repository and returns the created player',
        () async {
      final usecase = AddPlayer(repository);

      final result = await usecase(
        name: 'Luigi',
        icon: 'person',
        role: 'D',
        imagePath: '/path.jpg',
      );

      expect(repository.addCalls, 1);
      expect(result.isSuccess, isTrue);
      final player = result.fold((p) => p, (_) => null)!;
      expect(player.name, 'Luigi');
      expect(player.role, 'D');
      expect(player.imagePath, '/path.jpg');
    });
  });

  group('UpdatePlayer', () {
    test('forwards the updated entity to the repository', () async {
      final existing =
          const Player(id: 'p1', name: 'Mario', role: 'A', icon: 'star');
      repository.players.add(existing);
      final usecase = UpdatePlayer(repository);

      final updated = existing.copyWith(name: 'Mario Rossi');
      final result = await usecase(updated);

      expect(repository.updateCalls, 1);
      expect(result.fold((p) => p.name, (_) => null), 'Mario Rossi');
    });
  });

  group('DeletePlayer', () {
    test('forwards the id to the repository', () async {
      repository.players.add(
        const Player(id: 'p1', name: 'Mario', role: 'A', icon: 'star'),
      );
      final usecase = DeletePlayer(repository);

      final result = await usecase('p1');

      expect(repository.deleteCalls, 1);
      expect(result.isSuccess, isTrue);
      expect(repository.players, isEmpty);
    });
  });
}
