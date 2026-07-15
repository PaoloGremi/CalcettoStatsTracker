import 'dart:io';

import 'package:calcetto_tracker/data/hive_boxes.dart';
import 'package:calcetto_tracker/features/players/data/datasources/player_local_datasource.dart';
import 'package:calcetto_tracker/features/players/data/repositories/player_repository_impl.dart';
import 'package:calcetto_tracker/features/players/domain/entities/player.dart';
import 'package:calcetto_tracker/models/field_model.dart';
import 'package:calcetto_tracker/models/match_model.dart';
import 'package:calcetto_tracker/models/player_model.dart';
import 'package:calcetto_tracker/services/data_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late DataService dataService;
  late PlayerRepositoryImpl repository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('player_repository_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PlayerModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MatchModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FieldModelAdapter());
    HiveBoxes.playersBox = await Hive.openBox<PlayerModel>('playersBox');
    HiveBoxes.matchesBox = await Hive.openBox<MatchModel>('matchesBox');
    HiveBoxes.fieldsBox = await Hive.openBox<FieldModel>('fieldsBox');

    dataService = DataService();
    repository = PlayerRepositoryImpl(
      localDataSource: PlayerLocalDataSource(box: HiveBoxes.playersBox),
      dataService: dataService,
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('getAllPlayers returns an empty list when the box is empty', () async {
    final result = await repository.getAllPlayers();

    expect(result.isSuccess, isTrue);
    expect(result.fold((players) => players, (_) => null), isEmpty);
  });

  test('addPlayer persists the player and getAllPlayers sees it afterwards',
      () async {
    final addResult = await repository.addPlayer(
      name: 'Mario',
      icon: 'star',
      role: 'A',
    );
    expect(addResult.isSuccess, isTrue);

    final all = await repository.getAllPlayers();
    final players = all.fold((p) => p, (_) => <Player>[]);
    expect(players, hasLength(1));
    expect(players.first.name, 'Mario');
  });

  test('updatePlayer overwrites the stored fields for that id', () async {
    final added =
        (await repository.addPlayer(name: 'Mario', icon: 'star', role: 'A'))
            .fold((p) => p, (_) => null)!;

    await repository
        .updatePlayer(added.copyWith(name: 'Mario Rossi', role: 'D'));

    final all =
        (await repository.getAllPlayers()).fold((p) => p, (_) => <Player>[]);
    expect(all.single.name, 'Mario Rossi');
    expect(all.single.role, 'D');
  });

  test(
      'deletePlayer removes the player and cleans up references in existing matches',
      () async {
    final added =
        (await repository.addPlayer(name: 'Mario', icon: 'star', role: 'A'))
            .fold((p) => p, (_) => null)!;

    await dataService.addMatch(MatchModel(
      id: 'm1',
      date: DateTime(2025, 1, 1),
      teamA: [added.id],
      teamB: <String>[],
      fieldLocation: '',
      mvp: added.id,
      hustlePlayer: '',
      bestGoalPlayer: '',
      goals: {added.id: 2},
    ));

    final deleteResult = await repository.deletePlayer(added.id);
    expect(deleteResult.isSuccess, isTrue);

    final all =
        (await repository.getAllPlayers()).fold((p) => p, (_) => <Player>[]);
    expect(all, isEmpty);

    // La pulizia referenziale di DataService.deletePlayer deve aver
    // rimosso il giocatore anche dalla formazione/gol della partita.
    final match = HiveBoxes.matchesBox.get('m1')!;
    expect(match.teamA, isEmpty);
    expect(match.goals.containsKey(added.id), isFalse);
  });
}
