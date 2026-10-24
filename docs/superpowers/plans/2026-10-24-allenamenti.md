# Allenamenti individuali — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Diario personale degli allenamenti (corsa / tecnico / misto) con record, grafico del passo, heatmap e backup CSV.

**Architecture:** Nuovo modulo `lib/features/trainings/` in Clean Architecture come `features/players`, ma il repository scrive direttamente sul proprio box Hive (nessun legame con `DataService`). I calcoli stanno in una classe pura `TrainingStats`; la UI legge da un `TrainingsController` (`ChangeNotifier`, factory in `get_it`).

**Tech Stack:** Flutter/Dart, Hive + hive_generator, get_it, Provider, fl_chart, intl, uuid, csv; test con flutter_test + mocktail.

**Spec:** `docs/superpowers/specs/2026-10-24-allenamenti-design.md`

## Global Constraints
- Hive: `TrainingModel` `@HiveType(typeId: 3)`, box `'trainingsBox'` in `HiveBoxes.trainingsBox`; adapter generato (`dart run build_runner build --delete-conflicting-outputs`), mai scritto a mano; registrato in `main()` prima di `HiveBoxes.init()`.
- `type` e `categories` salvati come `enum.name` (stringhe); in lettura categoria sconosciuta → ignorata, tipo sconosciuto → `TrainingType.mixed`.
- Errori: `Result<T>`, Hive catturato nel repository come `CacheFailure`, validazione come `ValidationFailure`. Niente eccezioni oltre il repository.
- `TrainingsController` registrato come **factory** in `get_it`, fornito con `ChangeNotifierProvider` a livello di pagina.
- Colori solo via `AppTheme.*` (getter statici, mai `const`, mai come default di parametro). Un `CustomPainter` che legge `AppTheme` include `AppTheme.isLight` in `shouldRepaint`.
- Copy UI in italiano. Etichette: Corsa, Tecnico, Misto; Tiri, Sprint, Resistenza, Tecnica palla, Forza.
- Soglia passo migliore: `distanceKm >= 1.0`. Settimana = lunedì→domenica.
- Fake per test di usecase, mocktail per controller/UI (AGENTS.md).

## Review Focus
1. Modifica di un allenamento da Misto a Corsa: durata tecnica e categorie devono sparire dal salvato (Task 1 `normalized`, Task 4 `SaveTraining`).
2. Allenamento salvato con un orario (es. 23:30) o in un giorno di cambio ora legale: deve finire nel giorno giusto della heatmap e nella settimana giusta (Task 2, chiavi `DateTime.utc(y,m,d)`).
3. Input umani nel modulo: `5,2` e `5.2` km, tempo `45` (minuti), `25:30`, `1:02:05`, `5:75` rifiutato (Task 6 parse helpers).
4. Home su schermo piccolo (320×568) con la nuova card: nessun overflow (Task 8).
5. Note con virgole, virgolette e a capo nel CSV: devono tornare identiche dopo export→import (Task 9).

---

## File Structure
```
lib/features/trainings/
  domain/entities/training.dart              Training, TrainingType, TechnicalCategory
  domain/training_validation.dart            validateTraining()
  domain/services/training_stats.dart        TrainingStats, PacePoint
  domain/repositories/training_repository.dart
  domain/usecases/get_all_trainings.dart | save_training.dart | delete_training.dart
  data/models/training_model.dart (+ .g.dart)
  data/mappers/training_mapper.dart
  data/datasources/training_local_datasource.dart
  data/repositories/training_repository_impl.dart
  data/training_csv.dart                     codec puro righe CSV ↔ Training
  presentation/controllers/trainings_controller.dart
  presentation/training_format.dart          parse/format km, tempi, passo, giorno
  presentation/pages/trainings_page.dart
  presentation/pages/training_form_page.dart
  presentation/widgets/training_records_card.dart | pace_chart_card.dart |
                       training_heatmap.dart | training_list_tile.dart |
                       home_trainings_card.dart
Modify: lib/data/hive_boxes.dart, lib/main.dart, lib/core/di/service_locator.dart,
        lib/screens/home_screen.dart, lib/services/csv_service.dart, lib/screens/backup_screen.dart
test/features/trainings/...                  specchio delle cartelle sopra
```

---

### Task 1: Entità `Training` e validazione

**Files:**
- Create: `lib/features/trainings/domain/entities/training.dart`, `lib/features/trainings/domain/training_validation.dart`
- Test: `test/features/trainings/domain/training_test.dart`

**Interfaces:**
- Produces:
  - `enum TrainingType { running('Corsa'), technical('Tecnico'), mixed('Misto'); final String label; bool get hasRun; bool get hasTechnical; }` — `hasRun` per running/mixed, `hasTechnical` per technical/mixed.
  - `enum TechnicalCategory { shots('Tiri'), sprint('Sprint'), endurance('Resistenza'), ballSkills('Tecnica palla'), strength('Forza'); final String label; }`
  - `class Training` immutabile: `id`, `date` (DateTime), `type`, `int? durationMinutes`, `double? distanceKm`, `int? runSeconds`, `Set<TechnicalCategory> categories` (default `{}`), `String? notes`.
    - `double? get paceSecondsPerKm` — `runSeconds / distanceKm` se entrambi > 0, altrimenti null.
    - `int get totalMinutes` — `durationMinutes ?? 0` se `type.hasTechnical`, altrimenti `(runSeconds ?? 0) / 60` arrotondato.
    - `Training normalized()` — data troncata a `DateTime(y,m,d)`; se `!type.hasRun` → `distanceKm`/`runSeconds` null; se `!type.hasTechnical` → `durationMinutes` null e `categories` vuoto; `notes` trimmate, vuote → null.
    - `Training copyWith({...})` con tutti i campi tranne `id`.
  - `String? validateTraining(Training t, {required DateTime today})` — ritorna il primo messaggio di errore o null. Messaggi esatti, in quest'ordine:
    1. `'La data non può essere nel futuro'` (giorno di `t.date` dopo il giorno di `today`)
    2. `'Inserisci una distanza maggiore di zero'` (hasRun e distanceKm null/≤0)
    3. `'Inserisci un tempo di corsa maggiore di zero'` (hasRun e runSeconds null/≤0)
    4. `'Inserisci una durata maggiore di zero'` (hasTechnical e durationMinutes null/≤0)
    5. `'Scegli almeno una categoria tecnica'` (hasTechnical e categories vuoto)

- [ ] **Step 1: Write the failing tests** — nel file di test:
  - `pace is run seconds divided by km`: running 5.0 km, 1500 s → `paceSecondsPerKm == 300`.
  - `pace is null without run data`: technical → null.
  - `totalMinutes of a run comes from run seconds`: 1530 s → 26 (arrotondato).
  - `normalized drops technical fields when switching to running`: mixed con durata 60, `{shots}`, 5 km, 1500 s → `copyWith(type: running).normalized()` ha `durationMinutes == null`, `categories` vuoto, km e secondi invariati.
  - `normalized drops run fields for technical` e `normalized strips time and blank notes`: `DateTime(2026,10,23,23,30)` → `DateTime(2026,10,23)`; notes `'  '` → null.
  - Un test per ciascuno dei 5 messaggi di `validateTraining` + `valid mixed training returns null`; data = oggi con orario 23:59 è valida.
- [ ] **Step 2: Run** `flutter test test/features/trainings/domain/training_test.dart` — Expected: FAIL (file/simboli mancanti).
- [ ] **Step 3: Implement** entità e `validateTraining` come da Interfaces.
- [ ] **Step 4: Run** lo stesso comando — Expected: PASS.
- [ ] **Step 5: Commit** `feat(trainings): entità Training e validazione`

---

### Task 2: `TrainingStats`

**Files:**
- Create: `lib/features/trainings/domain/services/training_stats.dart`
- Test: `test/features/trainings/domain/training_stats_test.dart`

**Interfaces:**
- Consumes: `Training`, `TrainingType` (Task 1).
- Produces:
  - `class PacePoint { final DateTime date; final double secondsPerKm; }`
  - `class TrainingStats { TrainingStats(List<Training> trainings, {required DateTime today}); static const minKmForBestPace = 1.0; }` con getter:
    - `double? bestPaceSecondsPerKm` — min passo tra allenamenti con `hasRun` e `distanceKm >= 1.0`.
    - `double? longestRunKm`
    - `int bestWeekStreak`, `int currentWeekStreak`
    - `List<PacePoint> pacePoints` — ogni allenamento con passo non null, ordinati per data crescente.
    - `Map<DateTime, TrainingType> dayTypes` — chiavi `DateTime.utc(y,m,d)` (stesso formato di `heatmapDays()` in `lib/services/player_stats_summary.dart`); tipi diversi nello stesso giorno → `mixed`.
    - `List<int> activeYears` — anni con almeno un allenamento, crescenti.
    - `int thisWeekCount` — allenamenti nella settimana lun→dom di `today`.
    - `Training? latest` — data più recente.

Algoritmo serie (giorni contati come `DateTime.utc` per evitare problemi di ora legale): calcola l'insieme dei lunedì (`utcDay - (weekday-1) giorni`) delle settimane con allenamenti. `best` = sequenza più lunga di lunedì distanti 7 giorni. `current`: parti dal lunedì di `today` se presente, altrimenti dal lunedì precedente se presente, altrimenti 0; conta all'indietro finché i lunedì sono consecutivi.

- [ ] **Step 1: Write the failing tests**:
  - `empty list gives nulls and zeros` (tutti i getter: null / 0 / vuoti).
  - `best pace ignores runs shorter than 1 km`: 0.4 km in 80 s (200 s/km) e 5 km in 1500 s → `bestPaceSecondsPerKm == 300`.
  - `exactly 1 km counts for best pace`.
  - `longest run includes mixed trainings`.
  - `week streak spans the new year`: allenamenti 2025-12-24, 2025-12-31, 2026-01-07 → `bestWeekStreak == 3`.
  - `current streak survives an empty current week`: today = mer 2026-10-21, allenamenti solo nelle settimane del 2026-10-12 e 2026-10-05 → `currentWeekStreak == 2`.
  - `current streak resets after a full empty week`: ultimo allenamento 2026-10-01, today 2026-10-21 → 0.
  - `late-evening training lands on its own day`: date `DateTime(2026,3,29,23,30)` (cambio ora legale) → `dayTypes` contiene `DateTime.utc(2026,3,29)`.
  - `different types on the same day become mixed`.
  - `pace points are sorted by date`, `thisWeekCount counts Monday to Sunday`, `latest is the most recent`, `activeYears`.
- [ ] **Step 2: Run** `flutter test test/features/trainings/domain/training_stats_test.dart` — Expected: FAIL.
- [ ] **Step 3: Implement** `TrainingStats` (calcoli lazy o nel costruttore, nessuna eccezione con liste vuote).
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** `feat(trainings): statistiche e record`

---

### Task 3: Layer dati Hive

**Files:**
- Create: `lib/features/trainings/data/models/training_model.dart` (+ generato `training_model.g.dart`), `data/mappers/training_mapper.dart`, `data/datasources/training_local_datasource.dart`, `data/repositories/training_repository_impl.dart`, `domain/repositories/training_repository.dart`
- Modify: `lib/data/hive_boxes.dart` (aggiungi `static late Box<TrainingModel> trainingsBox;` e `openBox('trainingsBox')` in `init()`), `lib/main.dart` (`Hive.registerAdapter(TrainingModelAdapter());` dopo `FieldModelAdapter`)
- Test: `test/features/trainings/data/training_mapper_test.dart`, `test/features/trainings/data/training_repository_impl_test.dart`

**Interfaces:**
- Consumes: `Training` (Task 1).
- Produces:
  - `TrainingModel extends HiveObject`, `@HiveType(typeId: 3)`, campi `@HiveField` 0–7: `String id`, `DateTime date`, `String type`, `int? durationMinutes`, `double? distanceKm`, `int? runSeconds`, `List<String> categories`, `String? notes`.
  - `class TrainingMapper { const TrainingMapper(); Training toEntity(TrainingModel m); TrainingModel toModel(Training t); }` — regole nomi sconosciuti dai Global Constraints.
  - `class TrainingLocalDataSource { TrainingLocalDataSource({Box<TrainingModel>? box}); List<TrainingModel> getAll(); Future<void> put(TrainingModel m); Future<void> delete(String id); }` — default `HiveBoxes.trainingsBox`, chiave Hive = `id`.
  - `abstract class TrainingRepository { Future<Result<List<Training>>> getAllTrainings(); Future<Result<Training>> saveTraining(Training t); Future<Result<void>> deleteTraining(String id); }`
  - `TrainingRepositoryImpl({required TrainingLocalDataSource localDataSource, TrainingMapper mapper = const TrainingMapper()})` — `getAllTrainings` ordinato per data decrescente; `saveTraining` = upsert; errori → `CacheFailure('Impossibile <leggere|salvare|eliminare> gli allenamenti: $e')`.

- [ ] **Step 1: Write the model** e genera l'adapter: `dart run build_runner build --delete-conflicting-outputs` — Expected: crea `training_model.g.dart`, nessun conflitto con gli altri `.g.dart`.
- [ ] **Step 2: Write the failing tests**:
  - Mapper: `round trips every field`; `unknown category names are dropped` (`['shots','juggling']` → `{shots}`); `unknown type falls back to mixed`.
  - Repository (setup Hive come `test/features/players/data/player_repository_impl_test.dart`: temp dir, `Hive.registerAdapter(TrainingModelAdapter())` se `!Hive.isAdapterRegistered(3)`, `Hive.deleteFromDisk()` in tearDown): `empty box returns empty list`; `save then getAll returns it`; `saving the same id updates instead of duplicating`; `getAll is sorted newest first`; `delete removes it`; `closed box returns CacheFailure` (chiudi il box prima della chiamata).
- [ ] **Step 3: Run** `flutter test test/features/trainings/data/` — Expected: FAIL.
- [ ] **Step 4: Implement** mapper, datasource, repository, modifiche a `HiveBoxes` e `main.dart`.
- [ ] **Step 5: Run** `flutter test test/features/trainings/data/` e `flutter test` — Expected: PASS (inclusi i test esistenti che usano `HiveBoxes`).
- [ ] **Step 6: Commit** `feat(trainings): persistenza Hive degli allenamenti`

---

### Task 4: Usecase con fake

**Files:**
- Create: `lib/features/trainings/domain/usecases/get_all_trainings.dart`, `save_training.dart`, `delete_training.dart`
- Test: `test/features/trainings/domain/fake_training_repository.dart`, `test/features/trainings/domain/training_usecases_test.dart`

**Interfaces:**
- Consumes: `TrainingRepository` (Task 3), `validateTraining`, `Training.normalized` (Task 1).
- Produces:
  - `GetAllTrainings(TrainingRepository)` → `Future<Result<List<Training>>> call()`
  - `SaveTraining(TrainingRepository, {DateTime Function()? clock})` → `Future<Result<Training>> call(Training t)`: normalizza, valida con `today: clock()`, su errore `Result.failure(ValidationFailure(msg))` **senza** chiamare il repository, altrimenti salva la versione normalizzata.
  - `DeleteTraining(TrainingRepository)` → `Future<Result<void>> call(String id)`
  - `FakeTrainingRepository implements TrainingRepository` con `trainings` (lista), `shouldFail`, `failureToReturn`, contatori `saveCalls`/`deleteCalls`, stile `FakePlayerRepository`.

- [ ] **Step 1: Write the failing tests**: `get all forwards the repository result`; `save normalizes before persisting` (mixed→running salva senza categorie); `save returns ValidationFailure and does not hit the repository` (`saveCalls == 0`, messaggio `'Scegli almeno una categoria tecnica'`); `save rejects a future date using the injected clock`; `delete forwards the id`; `repository failure is passed through`.
- [ ] **Step 2: Run** `flutter test test/features/trainings/domain/training_usecases_test.dart` — Expected: FAIL.
- [ ] **Step 3: Implement** i tre usecase.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** `feat(trainings): usecase allenamenti`

---

### Task 5: Controller e DI

**Files:**
- Create: `lib/features/trainings/presentation/controllers/trainings_controller.dart`
- Modify: `lib/core/di/service_locator.dart`
- Test: `test/features/trainings/presentation/trainings_controller_test.dart`, `test/core/di/service_locator_test.dart`

**Interfaces:**
- Consumes: usecase del Task 4, `TrainingStats` (Task 2).
- Produces: `TrainingsController({required GetAllTrainings getAllTrainings, required SaveTraining saveTraining, required DeleteTraining deleteTraining, DateTime Function()? clock}) extends ChangeNotifier` con:
  - `List<Training> trainings` (decrescente), `bool isLoading` (iniziale true), `String? error`, `TrainingStats get stats` (ricalcolato quando cambia la lista, con `today: clock()`).
  - `Future<void> load()`
  - `Future<String?> save(Training t)` — null se ok (e ricarica), altrimenti il messaggio del `Failure` (non lo mette in `error`, lo mostra il modulo).
  - `Future<bool> remove(String id)` — su errore imposta `error`.
- DI: `registerFactory` per `TrainingLocalDataSource`, `TrainingRepository` (→ `TrainingRepositoryImpl`), i tre usecase e `TrainingsController`, in un blocco `// ── Feature: Trainings ──` dopo Players.

- [ ] **Step 1: Write the failing tests** (mocktail, stile `players_controller_test.dart`): `load exposes trainings and stats`; `load failure sets error`; `save returns null and reloads on success`; `save returns the validation message on failure`; `remove failure sets error`. In `service_locator_test.dart`: `TrainingsController is a factory` (`isNot(same(...))` tra due `getIt<TrainingsController>()`).
- [ ] **Step 2: Run** `flutter test test/features/trainings/presentation/trainings_controller_test.dart test/core/di/service_locator_test.dart` — Expected: FAIL.
- [ ] **Step 3: Implement** controller e registrazioni.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** `feat(trainings): controller e registrazione DI`

---

### Task 6: Helper di formato e modulo allenamento

**Files:**
- Create: `lib/features/trainings/presentation/training_format.dart`, `lib/features/trainings/presentation/pages/training_form_page.dart`
- Test: `test/features/trainings/presentation/training_format_test.dart`, `test/features/trainings/presentation/training_form_page_test.dart`

**Interfaces:**
- Consumes: `TrainingsController.save/remove` (Task 5), entità (Task 1).
- Produces:
  - `int? parseRunTime(String s)` — `'25:30'`→1530, `'1:02:05'`→3725, `'45'`→2700 (numero solo = minuti), `''`/`'abc'`/`'5:75'`/`'1:60:00'`/`'0:00'`→null. Spazi ignorati.
  - `double? parseKm(String s)` — `'5,2'` e `'5.2'`→5.2; vuoto/non numerico/≤0 → null.
  - `String formatKm(double km)` — `NumberFormat('#0.##', 'it_IT')`: 5.2→`'5,2'`, 10.0→`'10'`.
  - `String formatRunTime(int seconds)` — 1530→`'25:30'`, 3725→`'1:02:05'`.
  - `String formatPace(double secondsPerKm)` — arrotonda al secondo prima di dividere: 312.4→`'5:12'`, 299.6→`'5:00'`.
  - `String formatTrainingDay(DateTime date, DateTime today)` — `'Oggi'`, `'Ieri'`, altrimenti `formatDayMonthYear` da `lib/core/util/date_formatters.dart`.
  - `TrainingFormPage({Training? initial})` — legge `TrainingsController` dal `Provider`. Nuovo allenamento: `id = const Uuid().v4()`, data oggi, tipo Corsa. `SegmentedButton<TrainingType>`; campi visibili per tipo (tempo di corsa e km se `hasRun`, durata minuti e `FilterChip` per categoria se `hasTechnical`); selettore data (`showDatePicker`, `lastDate` oggi); note multilinea. "Salva" chiama `save`; se ritorna un messaggio lo mostra in `SnackBar`, altrimenti `Navigator.pop(context, true)`. Se `initial != null` mostra in AppBar "Elimina" → dialog "Eliminare questo allenamento?" → `remove` → pop. Key dei campi: `Key('run_time_field')`, `Key('distance_field')`, `Key('duration_field')`, `Key('save_button')`.

- [ ] **Step 1: Write the failing tests**:
  - Format: un test per ogni esempio delle Interfaces sopra.
  - Form (widget, `MaterialApp` + `ChangeNotifierProvider<TrainingsController>.value` con mock): `running shows only run fields`; `technical shows duration and categories only`; `mixed shows both`; `unparseable time shows "Formato tempo non valido"` sotto il campo, e `save` non chiamato; `validation message from controller appears in a SnackBar`; `editing prefills fields and delete asks for confirmation`.
- [ ] **Step 2: Run** `flutter test test/features/trainings/presentation/` — Expected: FAIL.
- [ ] **Step 3: Implement** helper e pagina. Errori di parsing per campo: `'Formato tempo non valido'`, `'Distanza non valida'`, `'Durata non valida'`.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** `feat(trainings): modulo inserimento e modifica`

---

### Task 7: Pagina progressi

**Files:**
- Create: `lib/features/trainings/presentation/pages/trainings_page.dart`, `presentation/widgets/training_records_card.dart`, `pace_chart_card.dart`, `training_heatmap.dart`, `training_list_tile.dart`
- Test: `test/features/trainings/presentation/trainings_page_test.dart`

**Interfaces:**
- Consumes: `TrainingsController` (Task 5), `TrainingStats`/`PacePoint` (Task 2), helper di formato (Task 6), `heatmapDays(int year)` da `lib/services/player_stats_summary.dart`.
- Produces:
  - `TrainingsPage` — crea il controller con `getIt<TrainingsController>()..load()` in un `ChangeNotifierProvider`; AppBar "Allenamenti" con `IconButton` + → `TrainingFormPage`. Corpo: loading → `CircularProgressIndicator`; lista vuota → "Nessun allenamento registrato" + pulsante "Aggiungi allenamento"; altrimenti `ListView` con, in ordine: records, grafico, heatmap, titolo "Storico", righe.
  - `TrainingRecordsCard(stats)` — tre valori: "Passo migliore" (`formatPace` + `/km`, o `'—'`), "Corsa più lunga" (`formatKm` + ` km`, o `'—'`), "Serie settimane" (`current` grande, `'record $best'` sotto).
  - `PaceChartCard(points)` — `LineChart` di fl_chart; con `< 2` punti mostra `'Servono almeno 2 corse per vedere l\'andamento'`. Asse Y invertito (più in alto = più veloce) e etichette con `formatPace`.
  - `TrainingHeatmap(dayTypes, activeYears, today)` — stessa griglia di `lib/screens/player_stats/activity_heatmap.dart` (celle 12, gap 3, `ChoiceChip` per anno, scroll orizzontale sulla settimana corrente), colore per tipo con legenda Corsa/Tecnico/Misto; giorni senza allenamento `AppTheme.border`.
  - `TrainingListTile(training, today, onTap)` — titolo `formatTrainingDay` · tipo; sottotitolo corsa `'5,2 km · 25:30 · 4:54/km'`, tecnico `'60 min · Tiri, Sprint'`, misto entrambi.
  - Tap su riga → `TrainingFormPage(initial: t)`; al ritorno `true` → `load()`.

- [ ] **Step 1: Write the failing tests** (mock del controller): `shows empty state`; `shows records, chart message with one run, and history rows`; `history row subtitle for a mixed training` (`'5,2 km · 25:30 · 4:54/km · 60 min · Tiri'`); `renders in light theme without exceptions` (`AppTheme.isLight = true`, ripristina in tearDown).
- [ ] **Step 2: Run** `flutter test test/features/trainings/presentation/trainings_page_test.dart` — Expected: FAIL.
- [ ] **Step 3: Implement** pagina e widget. Per i test, `TrainingsPage` accetta opzionalmente `TrainingsController? controller` (se null usa `getIt`).
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** `feat(trainings): pagina progressi`

---

### Task 8: Integrazione in home

**Files:**
- Create: `lib/features/trainings/presentation/widgets/home_trainings_card.dart`
- Modify: `lib/screens/home_screen.dart` (bottone + centrale ~riga 257; card tra `SmartNewsTicker` e il blocco info giocatore ~riga 170)
- Test: `test/features/trainings/presentation/home_trainings_card_test.dart`

**Interfaces:**
- Consumes: `TrainingsController`, `TrainingStats.latest/thisWeekCount`, `TrainingsPage`, `TrainingFormPage`.
- Produces:
  - `HomeTrainingsCard({TrainingsController? controller})` — altezza fissa 56, una riga: icona, testo principale (`'Ieri · Corsa 5,2 km · 5:12/km'` per l'ultimo allenamento; senza dati `'Registra il tuo primo allenamento'`), a destra `'N questa settimana'`. Tap → `TrainingsPage`, al ritorno `load()`.
  - Il + centrale apre `showModalBottomSheet` con due `ListTile`: "Nuova partita" (comportamento attuale: `NewMatchScreen` + `setState`) e "Nuovo allenamento" (`TrainingFormPage` dentro un `ChangeNotifierProvider` con `getIt<TrainingsController>()`; la card di home ricarica al ritorno).

- [ ] **Step 1: Write the failing tests**: `empty state text`; `latest training summary and weekly count`; `does not overflow at 320x568 with textScaler 1.3` (`tester.view.physicalSize`, nessuna eccezione di overflow).
- [ ] **Step 2: Run** `flutter test test/features/trainings/presentation/home_trainings_card_test.dart` — Expected: FAIL.
- [ ] **Step 3: Implement** card e modifiche a `home_screen.dart`.
- [ ] **Step 4: Run** `flutter test` e `flutter analyze` — Expected: PASS, nessun issue.
- [ ] **Step 5: Commit** `feat(trainings): accesso agli allenamenti dalla home`

---

### Task 9: Backup CSV

**Files:**
- Create: `lib/features/trainings/data/training_csv.dart`
- Modify: `lib/services/csv_service.dart` (`exportTrainings`, `importTrainings`, aggiunta in `exportAll`), `lib/screens/backup_screen.dart` (una `_ActionCard` "Esporta Allenamenti" e una "Importa Allenamenti", stile esistente)
- Test: `test/features/trainings/data/training_csv_test.dart`

**Interfaces:**
- Consumes: `TrainingModel` (Task 3).
- Produces:
  - `const trainingCsvHeader = ['id','date','type','duration_min','distance_km','run_seconds','categories','notes'];`
  - `List<List<String>> trainingsToCsvRows(List<TrainingModel> items)` — header + righe; data `dd/MM/yyyy`; km con punto decimale; null → `''`; categorie unite con `'|'`.
  - `TrainingModel? trainingFromCsvRow(List<dynamic> row)` — null se meno di 8 colonne, id vuoto, data o tipo non validi.
  - `CsvService.exportTrainings()` → `Future<File>` `trainings.csv`; `CsvService.importTrainings()` → `Future<ImportResult>`: salta id già presenti in `HiveBoxes.trainingsBox` e righe con `trainingFromCsvRow == null` (contati come `skipped`).

- [ ] **Step 1: Write the failing tests**: `round trip keeps every field` (passando per `ListToCsvConverter`/`CsvToListConverter` con gli stessi parametri di `CsvService._toCsv/_fromCsv`, `shouldParseNumbers: false`), con note `'Ripetute, "lente"\nseconda riga'`; `technical row has empty run columns`; `invalid date returns null`; `short row returns null`.
- [ ] **Step 2: Run** `flutter test test/features/trainings/data/training_csv_test.dart` — Expected: FAIL.
- [ ] **Step 3: Implement** codec e metodi di `CsvService`, voci in `BackupScreen`.
- [ ] **Step 4: Run** `flutter test` e `flutter analyze` — Expected: PASS, nessun issue.
- [ ] **Step 5: Commit** `feat(trainings): backup CSV degli allenamenti`

---

### Task 10: Verifica finale
- [ ] `flutter analyze` — Expected: `No issues found!`
- [ ] `flutter test` — Expected: `All tests passed!`
- [ ] Avvio su simulatore/dispositivo: crea una corsa, un tecnico e un misto; modifica il misto in corsa; controlla record, grafico, heatmap, card in home, tema chiaro e scuro; esporta e reimporta il CSV.
- [ ] Aggiorna `AGENTS.md`: la feature trainings è in Clean Architecture e **non** passa da `DataService`; typeId 3 occupato.
- [ ] Commit `docs: AGENTS.md aggiornato per la feature allenamenti`
