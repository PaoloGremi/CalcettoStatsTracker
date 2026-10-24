# Allenamenti individuali — design

Data: 2026-10-24 · Branch: `feat/allenamenti`

## Obiettivo
Un diario personale degli allenamenti fatti da soli (corsa, parte tecnica o
entrambe), separato da giocatori e partite. Serve a:
1. sapere in quali giorni ci si è allenati;
2. registrare le prestazioni di corsa e vederne i progressi nel tempo.

Gli allenamenti **non** sono legati a un giocatore della rosa. I dati si
inseriscono a mano (nessuna integrazione con Salute/Strava, nessun GPS).

## Modello dati

### Entità `Training` (dominio)
| Campo | Tipo | Obbligatorio |
|---|---|---|
| `id` | `String` (uuid) | sempre |
| `date` | `DateTime` (solo giorno) | sempre, default oggi |
| `type` | `TrainingType { running, technical, mixed }` | sempre |
| `durationMinutes` | `int?` | `technical` e `mixed` |
| `distanceKm` | `double?` | `running` e `mixed` |
| `runSeconds` | `int?` | `running` e `mixed` |
| `categories` | `Set<TechnicalCategory>` | ≥ 1 per `technical` e `mixed`; vuoto per `running` |
| `notes` | `String?` | no |

`TechnicalCategory { shots, sprint, endurance, ballSkills, strength }` —
etichette UI: Tiri, Sprint, Resistenza, Tecnica palla, Forza.

Valori derivati (getter, non salvati):
- `paceSecondsPerKm` = `runSeconds / distanceKm` (null se manca la corsa);
- `totalMinutes` = `durationMinutes` per technical/mixed, `runSeconds / 60`
  arrotondato per running (nella sola corsa il tempo di corsa è la durata).

### Validazione
Nel caso d'uso di salvataggio, restituisce `Result` con `ValidationFailure`:
- data non nel futuro;
- `running`/`mixed`: `distanceKm > 0` e `runSeconds > 0`;
- `technical`/`mixed`: `durationMinutes > 0` e almeno una categoria;
- campi non pertinenti al tipo vengono azzerati prima del salvataggio
  (es. passando da misto a corsa si svuotano categorie e durata).

### Persistenza
- `TrainingModel` con `@HiveType(typeId: 3)`, adapter generato con
  build_runner. Registrato in `main()` accanto agli altri adapter, prima di
  `HiveBoxes.init()`.
- Nuovo box `HiveBoxes.trainingsBox` (`'trainingsBox'`).
- `type` e `categories` salvati come **nomi stringa** (`enum.name`), non
  indici: riordinare o aggiungere valori non rompe i dati esistenti. Nomi
  sconosciuti in lettura vengono ignorati (categoria) o trattati come
  `mixed` (tipo).

## Architettura
Nuovo modulo `lib/features/trainings/`, stessa struttura di `features/players`:

```
domain/entities/training.dart            Training, TrainingType, TechnicalCategory
domain/repositories/training_repository.dart
domain/usecases/                         get_all_trainings, save_training, delete_training
domain/services/training_stats.dart      calcoli puri (vedi sotto)
data/models/training_model.dart (+ .g.dart)
data/datasources/training_local_datasource.dart
data/mappers/training_mapper.dart
data/repositories/training_repository_impl.dart
presentation/controllers/trainings_controller.dart   ChangeNotifier
presentation/pages/trainings_page.dart               progressi + storico
presentation/pages/training_form_page.dart           crea/modifica
presentation/widgets/                                record, grafico passo, heatmap, riga storico, card home
```

- Il repository scrive direttamente sul box: gli allenamenti non hanno
  relazioni con giocatori/partite, quindi **non** passano da `DataService`.
- Errori Hive catturati nel repository e restituiti come `CacheFailure`.
- `save_training` copre sia creazione sia modifica (upsert per `id`).
- DI: repository e usecase in `get_it`; `TrainingsController` registrato come
  **factory**, fornito a livello di pagina con `ChangeNotifierProvider`.
  La card in home ottiene il proprio controller allo stesso modo e ricarica
  al ritorno dalla navigazione.

## Schermate e flusso

1. **Pulsante + centrale (home)** → bottom sheet con "Nuova partita"
   (`NewMatchScreen`, flusso invariato) e "Nuovo allenamento"
   (`TrainingFormPage`).
2. **Card "Allenamenti" in home**: ultimo allenamento (es. "Ieri · Corsa
   5,2 km · 5:12/km") e numero di allenamenti nella settimana corrente.
   Senza dati: "Registra il tuo primo allenamento". Tap → `TrainingsPage`.
3. **`TrainingsPage`**, un'unica pagina scrollabile con + nell'AppBar:
   - record: passo migliore, corsa più lunga, serie di settimane (migliore e
     in corso);
   - grafico del passo nel tempo (`fl_chart`);
   - heatmap annuale colorata per tipo, stile `activity_heatmap` delle
     statistiche giocatore;
   - storico dal più recente; tap → modifica.
   - Stato vuoto: messaggio + pulsante per aggiungere.
4. **`TrainingFormPage`**: selettore tipo (Corsa / Tecnico / Misto); i campi
   visibili dipendono dal tipo. Tempo di corsa in formato `mm:ss` o
   `h:mm:ss`, distanza con virgola o punto decimale. In modifica c'è
   "Elimina" con dialog di conferma.

Tutti i colori via `AppTheme` (tema chiaro/scuro); un `CustomPainter` che li
legge include il tema in `shouldRepaint`.

## Statistiche (`TrainingStats`)
Classe pura: riceve `List<Training>` e una data "oggi", restituisce i valori.
- **Passo migliore**: minimo `paceSecondsPerKm` tra le corse con
  `distanceKm >= 1.0`. Null se nessuna.
- **Corsa più lunga**: massimo `distanceKm`.
- **Serie di settimane**: settimane consecutive lun→dom con almeno un
  allenamento di qualunque tipo. `bestWeekStreak` e `currentWeekStreak`
  (la serie in corso vale anche se la settimana attuale non ha ancora
  allenamenti, purché la precedente ne abbia; si azzera dopo una settimana
  intera vuota).
- **Punti del grafico**: `(date, pace)` per ogni allenamento con corsa,
  ordinati per data. Con meno di 2 punti la UI mostra "Servono almeno 2 corse
  per vedere l'andamento".
- **Giorni heatmap**: `Map<DateTime, TrainingType>`; più allenamenti di tipo
  diverso nello stesso giorno → `mixed`.
- **Settimana corrente** e **ultimo allenamento** per la card in home.

## Backup CSV
In `CsvService`:
- `exportTrainings()` → `trainings.csv`, incluso in `exportAll()`.
  Colonne: `id, date, type, duration_min, distance_km, run_seconds,
  categories, notes` (categorie separate da `|`, data `dd/MM/yyyy`).
- `importTrainings()`: salta gli `id` già presenti, conta importati/saltati;
  righe non valide vengono saltate.
- Nuove voci nella `BackupScreen` per esportare/importare gli allenamenti.

## Test
- `TrainingStats`: record, soglia 1 km, serie a cavallo dell'anno, serie in
  corso, giorni con tipi diversi.
- Usecase (`save`, `delete`, `get_all`) con fake scritti a mano
  (`test/features/trainings/fake_training_repository.dart`), validazione
  compresa.
- Repository su Hive con temp dir (`Hive.init`, adapter registrato a mano,
  `Hive.deleteFromDisk()` in tearDown).
- `TrainingsController` con `mocktail`.
- `TrainingFormPage`: campi visibili per tipo, messaggi di validazione.
- CSV: export → import produce gli stessi allenamenti.

## Fuori scope (prima versione)
Km per settimana/mese, riepilogo delle categorie tecniche, import da
Salute/Strava, tracciamento GPS, allenamenti di gruppo o per giocatore.
