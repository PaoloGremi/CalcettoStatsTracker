# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Stack
Flutter/Dart app (no web backend). Local storage: **Hive** (no SQLite, no Firebase). State: **Provider** for reactive UI, **get_it** for DI wiring. Tests: `flutter_test` + `mocktail`.

## Commands
```bash
flutter test                                      # all tests
flutter test test/core/error/result_test.dart    # single file
flutter test --name "success carries the value"  # single test by name
flutter analyze                                   # lint
dart run build_runner build --delete-conflicting-outputs  # regenerate Hive adapters (*.g.dart)
```

## Architecture: dual-layer split (partial migration)
- **`lib/features/players/`** — fully migrated to Clean Architecture: `domain/entities`, `domain/usecases`, `domain/repositories`, `data/` (datasource + mapper + repository), `presentation/controllers + pages`.
- **`lib/screens/` + `lib/services/DataService`** — legacy layer, still in use for matches/fields/stats. Not yet migrated.
- These two layers coexist intentionally. Do not collapse them.
- **`lib/features/trainings/`** — personal training log (running/walking/technical/mixed/swimming; walking has its own records and never counts toward run records — use `TrainingType.countsAsRun`; swimming records only a duration — use `hasDistance`/`hasDuration`/`hasTechnical`, never compare against a single type), also Clean Architecture. Unlike players it has **no link to `DataService`**: the repository writes straight to `HiveBoxes.trainingsBox`. Stats live in the pure `TrainingStats` class; `TrainingsController` is a get_it factory (the home screen owns one, shared with the + sheet and `TrainingsPage`).
- **`lib/features/calendar/`** — calendar of matches + trainings (year picker, 12 months scrolled vertically, fixed day panel at the bottom), opened from the home player card. `ActivityCalendar` (pure) groups by day and keeps only the main player's matches; `ActivityCalendarPage` takes matches as a list (home wraps it in `Consumer<DataService>`) and reuses the home `TrainingsController`. Separate from the legacy match-only `CalendarMatchScreen` reached from history.

## Critical coupling: `PlayerRepositoryImpl` must delegate writes to `DataService`
Mutations (`add`/`update`/`delete`) in [`PlayerRepositoryImpl`](lib/features/players/data/repositories/player_repository_impl.dart) call `DataService` instead of writing directly to the Hive box. `DataService` is the sole source of `notifyListeners()` for players — bypassing it silently breaks reactivity in un-migrated screens.

`deletePlayer` in `DataService` also does referential cleanup (removes player from match rosters, votes, goals). Reimplementing delete in the repository without calling `DataService.deletePlayer` would leave orphaned references.

## Error handling pattern
Operations that can fail return `Result<T>` (a custom sealed class in [`lib/core/error/result.dart`](lib/core/error/result.dart)), not exceptions or `Either`. Use `.fold(onSuccess, onFailure)` to consume. Do not throw across layer boundaries — catch at the repository boundary and wrap in `CacheFailure`/`NetworkFailure`/`ValidationFailure`.

## DI: `get_it` + `Provider` coexist by design
- `get_it` (`getIt`) wires data/domain dependencies (repository, usecases, `PlayersController`).
- `Provider` handles UI-reactive state (`DataService`, `PlayersController` at page scope).
- `PlayersController` is registered as **factory** (not singleton) — each page gets its own instance.
- `DataService` is a **lazy singleton** in both `get_it` and `Provider` (same instance, accessed via `getIt<DataService>()`).

## Hive model rules
- Hive typeIds in use: 0 `PlayerModel`, 1 `MatchModel`, 2 `FieldModel`, 3 `TrainingModel` (generated adapter, registered in `main()` before `HiveBoxes.init()`). `TrainingModel` stores enums by `.name`, never by index.
- `PlayerModel` uses `@HiveType(typeId: 0)` with `@HiveField` annotations; the `.g.dart` adapter is generated — never hand-write it.
- `HiveMigrationService.migratePlayersIfNeeded()` must be called in `main()` **after** `Hive.initFlutter()` and **before** `HiveBoxes.init()` — it registers `PlayerModelAdapter`. `HiveBoxes.init()` must not register it again.
- In tests requiring Hive: use `Hive.init(tempDir.path)` with a temp dir, register adapters manually, assign `HiveBoxes.*Box` directly, and call `Hive.deleteFromDisk()` in `tearDown`.

## Testing conventions
- **Use fakes** (hand-written `implements`) for domain usecase tests; **use `mocktail`** for controller/presentation tests.
- Fake implementations live in `test/…/fake_*.dart` alongside the tests that use them.
- `getIt` must be reset in `tearDown(() async { await getIt.reset(); })` in any test that calls `setupServiceLocator()`.
- Widget tests wrap the widget in `MaterialApp` + `ChangeNotifierProvider<T>.value(value: controller, ...)`.

## Theme (light/dark)
- `AppTheme` colors are **static getters**, not `const`: they read `AppTheme.isLight`, toggled by `ThemeController` (persisted in SharedPreferences, loaded in `main()`). Never wrap them in `const` and never use them as default parameter values — use a nullable param + `?? AppTheme.x` in `build`.
- On a theme change `CalcettoApp` marks the whole element tree dirty, so widgets reading `AppTheme.*` update without `Theme.of`. A `CustomPainter` that reads `AppTheme.*` must include the theme in `shouldRepaint`.
- Prefer `AppTheme` tokens over hardcoded `Colors.white`/`Color(0xFF1x1x1x)` on normal surfaces; hardcoded colors are fine on photos, the pitch, and self-styled sections (newspaper cards, AI coach).

## Utilities
- [`resolvePlayerName(id)`](lib/core/util/player_lookup.dart) — resolves player name from Hive by id with a fallback; use this everywhere instead of inline `HiveBoxes.playersBox.get(id)?.name` lookups.
- [`lib/data/player_icons.dart`](lib/data/player_icons.dart) — canonical list of available player icon names.
