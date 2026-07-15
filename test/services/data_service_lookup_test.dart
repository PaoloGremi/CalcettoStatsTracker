import 'dart:io';

import 'package:calcetto_tracker/data/hive_boxes.dart';
import 'package:calcetto_tracker/models/field_model.dart';
import 'package:calcetto_tracker/models/match_model.dart';
import 'package:calcetto_tracker/models/player_model.dart';
import 'package:calcetto_tracker/services/data_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late DataService dataService;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('data_service_lookup_test_');
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
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('getPlayerById returns the matching player', () async {
    final player =
        PlayerModel(id: 'p1', name: 'Mario', role: 'A', icon: 'star');
    await HiveBoxes.playersBox.put(player.id, player);

    expect(dataService.getPlayerById('p1')?.name, 'Mario');
  });

  test('getPlayerById returns null when the player does not exist', () {
    expect(dataService.getPlayerById('missing'), isNull);
  });

  test('getFieldById returns the matching field', () async {
    final field =
        FieldModel(id: 'f1', name: 'San Francesco', address: 'Via Roma 1');
    await HiveBoxes.fieldsBox.put(field.id, field);

    expect(dataService.getFieldById('f1')?.name, 'San Francesco');
  });

  test('getFieldById returns null when the field does not exist', () {
    expect(dataService.getFieldById('missing'), isNull);
  });

  test('matchCount reflects the number of stored matches', () async {
    expect(dataService.matchCount, 0);

    await HiveBoxes.matchesBox.put(
      'm1',
      MatchModel(
        id: 'm1',
        date: DateTime(2025, 1, 1),
        teamA: const [],
        teamB: const [],
        fieldLocation: '',
        mvp: '',
        hustlePlayer: '',
        bestGoalPlayer: '',
      ),
    );

    expect(dataService.matchCount, 1);
  });
}
