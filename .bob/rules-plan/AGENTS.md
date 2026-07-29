# Project Architecture Constraints (Non-Obvious Only)

- **Clean Architecture is partially applied** — only `lib/features/players/` is migrated. Any plan to migrate another feature (matches, fields, stats) must follow the same structure: `domain/{entities,repositories,usecases}`, `data/{datasources,mappers,repositories}`, `presentation/{controllers,pages,widgets}`.
- **`DataService` cannot be removed yet** — un-migrated screens depend on it for both state and Hive writes. New features must route mutations through it until those screens are also migrated, to preserve `notifyListeners()` reactivity.
- **Two DI systems are intentional and must coexist**: `Provider` for reactive UI state, `get_it` for wiring data/domain objects. Collapsing them would require migrating all `Provider.of<DataService>()` call sites in legacy screens.
- **Hive schema changes require a migration step** — add a new `_currentSchemaVersion` bump + migration pass in `HiveMigrationService`. There is no rollback mechanism; migrations are forward-only.
- **`PlayerRepositoryImpl` is a seam** — it wraps `DataService` to let the domain layer depend on an interface. If `DataService` is eventually broken apart, this impl is the place to rewire, not the usecases or controllers.
- **No background isolates, no streams** — all data access is synchronous Hive reads or `Future`-based writes. Reactive updates flow through `ChangeNotifier.notifyListeners()` only.
