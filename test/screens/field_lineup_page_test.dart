import 'dart:io';

import 'package:calcetto_tracker/data/hive_boxes.dart';
import 'package:calcetto_tracker/models/field_model.dart';
import 'package:calcetto_tracker/models/match_model.dart';
import 'package:calcetto_tracker/models/player_model.dart';
import 'package:calcetto_tracker/screens/field_lineup_page.dart';
import 'package:calcetto_tracker/services/data_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('field_lineup_page_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PlayerModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MatchModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FieldModelAdapter());
    HiveBoxes.playersBox = await Hive.openBox<PlayerModel>('playersBox');
    HiveBoxes.matchesBox = await Hive.openBox<MatchModel>('matchesBox');
    HiveBoxes.fieldsBox = await Hive.openBox<FieldModel>('fieldsBox');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('player tokens render without overflowing', (tester) async {
    final ids = <String>[];
    await tester.runAsync(() async {
      for (var i = 0; i < 10; i++) {
        final p = PlayerModel(
            id: 'p$i', name: 'Mario Rossi $i', role: 'C', icon: 'person');
        await HiveBoxes.playersBox.put(p.id, p);
        ids.add(p.id);
      }
    });

    await tester.pumpWidget(ChangeNotifierProvider<DataService>.value(
      value: DataService(),
      child: MaterialApp(
        home: FieldLineupPage(
            teamWhite: ids.sublist(0, 5), teamBlack: ids.sublist(5)),
      ),
    ));
    // Più frame: l'overflow viene segnalato solo quando i token, dopo
    // l'animazione di entrata, vengono effettivamente dipinti.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
  });
}
