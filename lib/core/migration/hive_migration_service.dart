import 'package:hive/hive.dart';

import '../../models/player_model.dart';
import 'legacy_player_adapter.dart';

/// Migra il box `playersBox` dal vecchio formato binario (adapter scritto
/// a mano, posizionale) al formato generato da `hive_generator` per
/// [PlayerModel] (frame `numOfFields` + coppie `(fieldIndex, value)`).
///
/// I due formati NON sono binariamente compatibili: un semplice swap
/// dell'adapter registrato per lo stesso typeId corromperebbe (o renderebbe
/// illeggibili) i dati già salvati sui device. Per questo la migrazione è
/// esplicita: legge tutto con il vecchio adapter, elimina il box dal disco
/// e lo riscrive da zero con quello nuovo, in un'unica passata idempotente
/// eseguita al primo avvio dopo l'aggiornamento.
///
/// Va chiamata una sola volta in `main()`, dopo `Hive.initFlutter()` e
/// PRIMA di `HiveBoxes.init()` — è questa funzione a registrare
/// [PlayerModelAdapter], `HiveBoxes.init()` non deve farlo di nuovo.
class HiveMigrationService {
  static const _metaBoxName = 'appMetaBox';
  static const _schemaVersionKey = 'playersSchemaVersion';
  static const _playersBoxName = 'playersBox';

  /// Versione di schema corrente per il box players. Bump-are solo se in
  /// futuro serve un'altra migrazione dei dati giocatori.
  static const _currentSchemaVersion = 1;

  static Future<void> migratePlayersIfNeeded() async {
    final metaBox = await Hive.openBox(_metaBoxName);
    final storedVersion = metaBox.get(_schemaVersionKey) as int?;

    if (storedVersion == _currentSchemaVersion) {
      // Già migrato (o installazione già sullo schema nuovo): idempotente.
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PlayerModelAdapter());
      }
      return;
    }

    final legacyBoxExists = await Hive.boxExists(_playersBoxName);
    if (!legacyBoxExists) {
      // Installazione pulita: nessun dato da migrare.
      Hive.registerAdapter(PlayerModelAdapter());
      await metaBox.put(_schemaVersionKey, _currentSchemaVersion);
      return;
    }

    // 1) Leggi tutto con il vecchio adapter posizionale.
    Hive.registerAdapter(LegacyPlayerAdapter());
    final legacyBox = await Hive.openBox<LegacyPlayerRecord>(_playersBoxName);
    final migratedRecords = <dynamic, LegacyPlayerRecord>{
      for (final key in legacyBox.keys) key: legacyBox.get(key)!,
    };
    await legacyBox.close();

    // 2) Elimina il box legacy dal disco (solo ora che è tutto in memoria)
    //    e sostituisci l'adapter registrato per lo stesso typeId.
    await Hive.deleteBoxFromDisk(_playersBoxName);
    Hive.registerAdapter(PlayerModelAdapter(), override: true);

    // 3) Riscrivi ogni record nel nuovo formato, stesse chiavi.
    final newBox = await Hive.openBox<PlayerModel>(_playersBoxName);
    for (final entry in migratedRecords.entries) {
      final r = entry.value;
      await newBox.put(
        entry.key,
        PlayerModel(
          id: r.id,
          name: r.name,
          role: r.role,
          icon: r.icon,
          imagePath: r.imagePath,
          mvpCount: r.mvpCount,
          hustleCount: r.hustleCount,
          bestGoalCount: r.bestGoalCount,
          totalGoals: r.totalGoals,
        ),
      );
    }

    await metaBox.put(_schemaVersionKey, _currentSchemaVersion);
  }
}
