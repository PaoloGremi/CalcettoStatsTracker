import 'dart:io';

import 'package:calcetto_tracker/data/hive_boxes.dart';
import 'package:calcetto_tracker/models/field_model.dart';
import 'package:calcetto_tracker/models/match_model.dart';
import 'package:calcetto_tracker/models/player_model.dart';
import 'package:calcetto_tracker/screens/match_promo_form_page.dart';
import 'package:calcetto_tracker/services/data_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main() {
  late Directory tempDir;

  setUpAll(() => initializeDateFormatting('it_IT'));

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('promo_form_test_');
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

  testWidgets('selecting a field with an address does not overflow',
      (tester) async {
    await tester.runAsync(() => HiveBoxes.fieldsBox.put(
        'f1',
        FieldModel(
            id: 'f1', name: 'San Francesco', address: 'Via Roma 1, Milano')));

    await tester.pumpWidget(ChangeNotifierProvider<DataService>.value(
      value: DataService(),
      child: const MaterialApp(home: MatchPromoFormPage()),
    ));
    await tester.pumpAndSettle();

    // Apre il menu dei campi e sceglie il campo.
    await tester.tap(find.text('— Nessuno —').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'menu aperto');

    await tester.tap(find.text('San Francesco').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'campo selezionato');
    // Il campo chiuso mostra il campo scelto su una riga.
    expect(
        find.textContaining('San Francesco · Via Roma 1, Milano',
            findRichText: true),
        findsOneWidget);
  });
}
