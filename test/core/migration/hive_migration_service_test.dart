import 'dart:async';
import 'dart:io';

import 'package:calcetto_tracker/core/migration/hive_migration_service.dart';
import 'package:calcetto_tracker/core/migration/legacy_player_adapter.dart';
import 'package:calcetto_tracker/data/hive_boxes.dart';
import 'package:calcetto_tracker/models/player_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Simula il record scritto da una versione dell'app precedente
/// all'introduzione di mvpCount/hustleCount/bestGoalCount/totalGoals:
/// solo i primi 4 campi (id, name, role, icon) sono presenti su disco.
class _TruncatedRecord {
  final String id, name, role, icon;
  _TruncatedRecord(
      {required this.id,
      required this.name,
      required this.role,
      required this.icon});
}

class _TruncatedLegacyAdapter extends TypeAdapter<_TruncatedRecord> {
  @override
  final int typeId = 0;

  @override
  _TruncatedRecord read(BinaryReader reader) => _TruncatedRecord(
        id: reader.readString(),
        name: reader.readString(),
        role: reader.readString(),
        icon: reader.readString(),
      );

  @override
  void write(BinaryWriter writer, _TruncatedRecord obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.role);
    writer.writeString(obj.icon);
    // Nessun campo aggiuntivo: schema pre-contatori.
  }
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('hive_migration_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    Hive.resetAdapters();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Scrive il box `playersBox` nel vecchio formato binario, come faceva
  /// l'app prima di questa migrazione (adapter scritto a mano).
  Future<void> writeLegacyBox(Map<String, LegacyPlayerRecord> records) async {
    Hive.registerAdapter(LegacyPlayerAdapter());
    final box = await Hive.openBox<LegacyPlayerRecord>('playersBox');
    for (final entry in records.entries) {
      await box.put(entry.key, entry.value);
    }
    await box.close();
    Hive.resetAdapters();
  }

  test('migrates existing legacy data to PlayerModel, field by field',
      () async {
    await writeLegacyBox({
      'p1': const LegacyPlayerRecord(
        id: 'p1',
        name: 'Mario',
        role: 'A',
        icon: 'star',
        imagePath: '/path/to/photo.jpg',
        mvpCount: 3,
        hustleCount: 1,
        bestGoalCount: 2,
        totalGoals: 15,
      ),
      'p2': const LegacyPlayerRecord(
        id: 'p2',
        name: 'Luigi',
        role: 'D',
        icon: 'person',
      ),
    });

    await HiveMigrationService.migratePlayersIfNeeded();
    await HiveBoxes.init();

    expect(HiveBoxes.playersBox.keys.toSet(), {'p1', 'p2'});

    final p1 = HiveBoxes.playersBox.get('p1')!;
    expect(p1.id, 'p1');
    expect(p1.name, 'Mario');
    expect(p1.role, 'A');
    expect(p1.icon, 'star');
    expect(p1.imagePath, '/path/to/photo.jpg');
    expect(p1.mvpCount, 3);
    expect(p1.hustleCount, 1);
    expect(p1.bestGoalCount, 2);
    expect(p1.totalGoals, 15);

    final p2 = HiveBoxes.playersBox.get('p2')!;
    expect(p2.imagePath, isNull);
    expect(p2.mvpCount, 0);
    expect(p2.hustleCount, 0);
    expect(p2.bestGoalCount, 0);
    expect(p2.totalGoals, 0);
  });

  test(
      'migrates a truncated legacy record (pre-counters schema) falling back to zero/null',
      () async {
    Hive.registerAdapter(_TruncatedLegacyAdapter());
    final box = await Hive.openBox<_TruncatedRecord>('playersBox');
    await box.put(
      'old1',
      _TruncatedRecord(id: 'old1', name: 'Vecchio', role: 'C', icon: 'person'),
    );
    await box.close();
    Hive.resetAdapters();

    await HiveMigrationService.migratePlayersIfNeeded();
    await HiveBoxes.init();

    final migrated = HiveBoxes.playersBox.get('old1')!;
    expect(migrated.name, 'Vecchio');
    expect(migrated.role, 'C');
    expect(migrated.icon, 'person');
    expect(migrated.imagePath, isNull);
    expect(migrated.mvpCount, 0);
    expect(migrated.hustleCount, 0);
    expect(migrated.bestGoalCount, 0);
    expect(migrated.totalGoals, 0);
  });

  test('is idempotent: running the migration twice does not alter the data',
      () async {
    await writeLegacyBox({
      'p1': const LegacyPlayerRecord(
          id: 'p1', name: 'Mario', role: 'A', icon: 'star'),
    });

    await HiveMigrationService.migratePlayersIfNeeded();
    await HiveMigrationService.migratePlayersIfNeeded(); // no-op atteso
    await HiveBoxes.init();

    expect(HiveBoxes.playersBox.keys.toList(), ['p1']);
    expect(HiveBoxes.playersBox.get('p1')!.name, 'Mario');
  });

  test(
      'clean install (nessun box preesistente) registra l\'adapter senza migrare nulla',
      () async {
    await HiveMigrationService.migratePlayersIfNeeded();
    await HiveBoxes.init();

    expect(HiveBoxes.playersBox.keys, isEmpty);

    await HiveBoxes.playersBox.put(
      'new1',
      PlayerModel(id: 'new1', name: 'Nuovo', role: 'P', icon: 'shield'),
    );
    expect(HiveBoxes.playersBox.get('new1')!.name, 'Nuovo');
  });

  test(
      'canary: leggere byte in formato legacy col solo adapter generato (senza migrazione) fallisce',
      () async {
    // Guardia contro la rimozione accidentale della migrazione in futuro:
    // se in futuro qualcuno "semplificasse" registrando solo
    // PlayerModelAdapter su un box scritto in formato legacy, la lettura
    // deve fallire — a dimostrazione che lo swap diretto dell'adapter NON
    // è un'alternativa valida alla migrazione esplicita.
    await writeLegacyBox({
      'p1': const LegacyPlayerRecord(
          id: 'p1', name: 'Mario', role: 'A', icon: 'star'),
    });

    Hive.registerAdapter(PlayerModelAdapter());

    // La lettura fallisce dentro il frame-reader interno di Hive, che la
    // segnala come errore di zona asincrono invece che come rejection
    // "pulita" del Future restituito da openBox — runZonedGuarded è
    // l'unico modo affidabile di intercettarla in questo contesto di test.
    final completer = Completer<Object>();
    await runZonedGuarded(() async {
      try {
        await Hive.openBox<PlayerModel>('playersBox');
        if (!completer.isCompleted) {
          completer.complete(StateError('la lettura non ha sollevato errori'));
        }
      } catch (e) {
        if (!completer.isCompleted) completer.complete(e);
      }
    }, (error, stack) {
      if (!completer.isCompleted) completer.complete(error);
    });

    final result = await completer.future;
    expect(
      result,
      isNot(isA<StateError>()),
      reason: 'la lettura di dati legacy col solo adapter generato '
          'dovrebbe fallire; se questo test inizia a passare, la '
          'migrazione esplicita non è più necessaria (o è stata rimossa '
          'per errore)',
    );
  });
}
