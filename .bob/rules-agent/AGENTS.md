# Project Coding Rules (Non-Obvious Only)

- **Never write directly to Hive boxes in `PlayerRepositoryImpl`** — all mutations must go through `DataService` methods (add/update/deletePlayer). Direct box writes skip `notifyListeners()` and orphan match references on delete.
- **`Result<T>` not exceptions** — repositories catch all exceptions and return `Result.failure(CacheFailure(...))`. Never let exceptions propagate past the repository boundary.
- **`role` is a plain String** (`'P'`, `'D'`, `'C'`, `'A'`), not an enum — intentional, for binary compatibility with `PlayerModel`. Don't introduce a `Role` enum without migrating the Hive model.
- **Hive adapter regeneration**: after changing a `@HiveType`/`@HiveField` annotated model, run `dart run build_runner build --delete-conflicting-outputs`. The `.g.dart` files are committed.
- **Startup order in `main()`**: `Hive.initFlutter()` → `HiveMigrationService.migratePlayersIfNeeded()` → register `MatchModelAdapter`/`FieldModelAdapter` → `HiveBoxes.init()` → `setupServiceLocator()`. Changing this order breaks migration or double-registers adapters.
- **`PlayersController` is factory-scoped** in get_it — do not change it to a singleton or you'll get stale player state across navigations.
- Use `resolvePlayerName(id)` from `lib/core/util/player_lookup.dart` for any id→name resolution; don't inline `HiveBoxes.playersBox.get(id)?.name`.
- Widget tests must wrap subjects in `MaterialApp` + `ChangeNotifierProvider<T>.value(...)` — bare `pumpWidget` will throw a missing-provider exception.
- In Hive integration tests: manually assign `HiveBoxes.*Box` after opening boxes on a temp dir; `tearDown` must call `Hive.deleteFromDisk()` then delete the temp dir.
