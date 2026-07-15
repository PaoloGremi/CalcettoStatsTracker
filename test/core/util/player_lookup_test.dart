import 'dart:io';

import 'package:calcetto_tracker/core/util/player_lookup.dart';
import 'package:calcetto_tracker/data/hive_boxes.dart';
import 'package:calcetto_tracker/models/player_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('player_lookup_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PlayerModelAdapter());
    }
    HiveBoxes.playersBox = await Hive.openBox<PlayerModel>('playersBox');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('returns the player name when the id exists', () async {
    final player =
        PlayerModel(id: 'p1', name: 'Mario', role: 'A', icon: 'star');
    await HiveBoxes.playersBox.put(player.id, player);

    expect(resolvePlayerName('p1'), 'Mario');
  });

  test('returns an empty string for an empty id', () {
    expect(resolvePlayerName(''), '');
  });

  test('falls back to the id itself when the player no longer exists', () {
    expect(resolvePlayerName('deleted-id'), 'deleted-id');
  });

  test('falls back to a custom fallback when provided', () {
    expect(resolvePlayerName('deleted-id', fallback: '?'), '?');
  });
}
