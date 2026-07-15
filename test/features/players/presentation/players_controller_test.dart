import 'package:calcetto_tracker/core/error/failure.dart';
import 'package:calcetto_tracker/core/error/result.dart';
import 'package:calcetto_tracker/features/players/domain/entities/player.dart';
import 'package:calcetto_tracker/features/players/domain/usecases/add_player.dart';
import 'package:calcetto_tracker/features/players/domain/usecases/delete_player.dart';
import 'package:calcetto_tracker/features/players/domain/usecases/get_all_players.dart';
import 'package:calcetto_tracker/features/players/domain/usecases/update_player.dart';
import 'package:calcetto_tracker/features/players/presentation/controllers/players_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAllPlayers extends Mock implements GetAllPlayers {}

class MockAddPlayer extends Mock implements AddPlayer {}

class MockUpdatePlayer extends Mock implements UpdatePlayer {}

class MockDeletePlayer extends Mock implements DeletePlayer {}

const _samplePlayer = Player(id: 'p1', name: 'Mario', role: 'A', icon: 'star');

void main() {
  late MockGetAllPlayers getAllPlayers;
  late MockAddPlayer addPlayer;
  late MockUpdatePlayer updatePlayer;
  late MockDeletePlayer deletePlayer;
  late PlayersController controller;

  setUpAll(() {
    registerFallbackValue(_samplePlayer);
  });

  setUp(() {
    getAllPlayers = MockGetAllPlayers();
    addPlayer = MockAddPlayer();
    updatePlayer = MockUpdatePlayer();
    deletePlayer = MockDeletePlayer();
    controller = PlayersController(
      getAllPlayers: getAllPlayers,
      addPlayer: addPlayer,
      updatePlayer: updatePlayer,
      deletePlayer: deletePlayer,
    );
  });

  test('starts in a loading state before load() is called', () {
    expect(controller.isLoading, isTrue);
    expect(controller.players, isEmpty);
  });

  group('load', () {
    test(
        'populates players sorted by name (case-insensitive) and clears isLoading',
        () async {
      when(() => getAllPlayers()).thenAnswer((_) async => Result.success(const [
            Player(id: 'p2', name: 'zeta', role: 'A', icon: 'x'),
            Player(id: 'p1', name: 'Alpha', role: 'D', icon: 'x'),
          ]));

      await controller.load();

      expect(controller.isLoading, isFalse);
      expect(controller.players.map((p) => p.name).toList(), ['Alpha', 'zeta']);
      expect(controller.error, isNull);
    });

    test('sets error and stops loading on failure', () async {
      when(() => getAllPlayers())
          .thenAnswer((_) async => Result.failure(const CacheFailure('boom')));

      await controller.load();

      expect(controller.isLoading, isFalse);
      expect(controller.error, 'boom');
    });

    test('notifies listeners', () async {
      when(() => getAllPlayers())
          .thenAnswer((_) async => Result.success(const []));
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      expect(notifications, greaterThan(0));
    });
  });

  group('add', () {
    test('on success, reloads the list and returns true', () async {
      when(() => addPlayer(
            name: any(named: 'name'),
            icon: any(named: 'icon'),
            role: any(named: 'role'),
            imagePath: any(named: 'imagePath'),
          )).thenAnswer((_) async => Result.success(_samplePlayer));
      when(() => getAllPlayers())
          .thenAnswer((_) async => Result.success(const [_samplePlayer]));

      final ok = await controller.add(name: 'Mario', icon: 'star', role: 'A');

      expect(ok, isTrue);
      expect(controller.players, hasLength(1));
      verify(() => getAllPlayers()).called(1);
    });

    test('on failure, sets error and does not reload', () async {
      when(() => addPlayer(
                name: any(named: 'name'),
                icon: any(named: 'icon'),
                role: any(named: 'role'),
                imagePath: any(named: 'imagePath'),
              ))
          .thenAnswer((_) async => Result.failure(const CacheFailure('nope')));

      final ok = await controller.add(name: 'Mario', icon: 'star', role: 'A');

      expect(ok, isFalse);
      expect(controller.error, 'nope');
      verifyNever(() => getAllPlayers());
    });
  });

  group('update', () {
    test('on success, reloads the list and returns true', () async {
      when(() => updatePlayer(any()))
          .thenAnswer((_) async => Result.success(_samplePlayer));
      when(() => getAllPlayers())
          .thenAnswer((_) async => Result.success(const [_samplePlayer]));

      final ok = await controller.update(_samplePlayer);

      expect(ok, isTrue);
      verify(() => getAllPlayers()).called(1);
    });

    test('on failure, sets error and does not reload', () async {
      when(() => updatePlayer(any()))
          .thenAnswer((_) async => Result.failure(const CacheFailure('nope')));

      final ok = await controller.update(_samplePlayer);

      expect(ok, isFalse);
      expect(controller.error, 'nope');
      verifyNever(() => getAllPlayers());
    });
  });

  group('remove', () {
    test('on success, reloads the list and returns true', () async {
      when(() => deletePlayer(any()))
          .thenAnswer((_) async => Result.success(null));
      when(() => getAllPlayers())
          .thenAnswer((_) async => Result.success(const []));

      final ok = await controller.remove('p1');

      expect(ok, isTrue);
      verify(() => getAllPlayers()).called(1);
    });

    test('on failure, sets error and does not reload', () async {
      when(() => deletePlayer(any()))
          .thenAnswer((_) async => Result.failure(const CacheFailure('nope')));

      final ok = await controller.remove('p1');

      expect(ok, isFalse);
      expect(controller.error, 'nope');
      verifyNever(() => getAllPlayers());
    });
  });
}
