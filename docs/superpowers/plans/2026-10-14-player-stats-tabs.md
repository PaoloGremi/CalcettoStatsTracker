# Statistiche giocatore a tab — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trasformare `PlayerStatsScreen` (≈3.160 righe, ≈25 sezioni in lista) in una schermata a 7 tab, con i calcoli estratti in una classe pura testata e tre nuovi gruppi di statistiche.

**Architecture:** `PlayerStatsSummary.compute(...)` (Dart puro, in `lib/services/`) calcola una sola volta tutti i valori; `PlayerStatsScreen` diventa un guscio (intestazione compatta + `TabBar` + `TabBarView`) e ogni tab è un file `part of` della stessa libreria in `lib/screens/player_stats/`, così i widget privati esistenti (`_StatBox`, `_ChartCard`, …) si spostano senza rinominarli.

**Tech Stack:** Flutter, Provider (`DataService`), Hive, fl_chart ^0.69, flutter_test.

**Spec:** [docs/superpowers/specs/2026-10-14-player-stats-tabs-design.md](../specs/2026-10-14-player-stats-tabs-design.md)

## Global Constraints

- Nessuna modifica a `MatchModel`, `PlayerModel`, adapter Hive o `HiveMigrationService`.
- La schermata resta legacy (`lib/screens/` + `DataService`); niente migrazione in `lib/features/`.
- Le sezioni esistenti si spostano **senza cambiarne grafici né calcoli**.
- `PlayerStatsSummary` non importa Flutter, Hive né fl_chart: solo `dart:core`/`dart:math` e `MatchModel`. La conversione in `FlSpot` avviene nelle tab.
- Il summary non lancia mai eccezioni; nessuna divisione per zero.
- Ordine tab e etichette: `PANORAMICA`, `VOTI`, `GOL`, `RISULTATI`, `RECORD`, `COMPAGNI`, `STAGIONI`.
- Tab senza nessuna sezione visibile → testo `Dati insufficienti per questa categoria`.
- Test che usano `DataService` seguono le convenzioni Hive di AGENTS.md (temp dir, adapter registrati a mano, box assegnati, `Hive.deleteFromDisk()` in `tearDown`).
- Lavorare su un branch `feature/player-stats-tabs`, un commit per task.

## Review Focus

1. **Giocatore con partite ma zero voti** — le tab Panoramica/Voti non devono andare in crash (gli attuali `reduce` su liste vuote); Voti mostra il messaggio "Dati insufficienti". → test in Task 1 e Task 2.
2. **Mappa presenze attraverso il cambio dell'ora legale** — iterare i giorni con `DateTime` locale + `Duration(days: 1)` salta o duplica un giorno a fine marzo/ottobre. → usare `DateTime.utc` per la griglia; test in Task 7.
3. **Partite con orario diverso nello stesso giorno** — la mappa e il giorno della settimana devono raggruppare per (anno, mese, giorno), non per `DateTime` esatto; vince l'ultima per orario. → test in Task 7.
4. **Partite 0–0 / squadra che non segna mai** — la quota gol è nascosta (denominatore 0), la differenza reti è `0.0`. → test in Task 4 e Task 5.
5. **Una sola partita giocata** — tutte le serie valgono 1 con inizio = fine, la media mobile/rolling non compaiono, il confronto anni non compare. → test in Task 6 e Task 7.

---

## File Structure

| File | Responsabilità |
|---|---|
| `lib/services/player_stats_summary.dart` (nuovo) | Classe immutabile `PlayerStatsSummary` + record/enum di supporto; tutti i calcoli. |
| `lib/screens/player_stats_screen.dart` (riscritto) | `library`; `part` dei file tab; guscio con intestazione compatta, `DefaultTabController`, stato vuoto. |
| `lib/screens/player_stats/stats_widgets.dart` (nuovo, `part of`) | Widget condivisi spostati: `_StatBox`, `_LegendRow`, `_ChartCard`, `_ResultAvgBadge`, `_ConsistStat`, `_EmptyTab`. |
| `lib/screens/player_stats/overview_tab.dart` | `_OverviewTab` + `_RadarCard`, `_TabButton`, `_RadarLegendItem`. |
| `lib/screens/player_stats/votes_tab.dart` | `_VotesTab` + `_ConsistencyCard` + nuovo `_RelativeVoteCard`. |
| `lib/screens/player_stats/goals_tab.dart` | `_GoalsTab` + nuovi `_GoalShareCard`, `_MultiGoalCard`. |
| `lib/screens/player_stats/results_tab.dart` | `_ResultsTab` + `_FieldStatsCard`, `_FieldStat`, `_FieldMetric` + nuovi `_GoalDiffCard`, `_MarginsCard`. |
| `lib/screens/player_stats/records_tab.dart` | `_RecordsTab` + `_MilestonesCard` + nuovi `_StreaksCard`, `_BestMatchCard`. |
| `lib/screens/player_stats/teammates_tab.dart` | `_TeammatesTab` (ChemistryBubbleChart, ChemistryRadarChart). |
| `lib/screens/player_stats/seasons_tab.dart` | `_SeasonsTab` + nuovi `_ActivityHeatmap`, `_WeekdayCard`, `_YearComparisonCard`. |
| `test/services/player_stats_summary_test.dart` (nuovo) | Test unitari del summary. |
| `test/screens/player_stats_screen_test.dart` (nuovo) | Widget test del guscio e delle tab. |

---

### Task 1: Estrarre `PlayerStatsSummary` (solo calcoli esistenti)

**Files:**
- Create: `lib/services/player_stats_summary.dart`
- Test: `test/services/player_stats_summary_test.dart`

**Interfaces:**
- Produces:
  ```dart
  enum MatchOutcome { win, draw, loss }   // label: 'V' | 'P' | 'S'
  typedef VotePoint = ({int matchIndex, double vote});
  typedef RecentResult = ({MatchOutcome outcome, double? vote, DateTime date});

  class PlayerStatsSummary {
    static PlayerStatsSummary compute({
      required String playerId,
      required List<MatchModel> allMatches,   // tutte le partite registrate, qualsiasi ordine
    });
    final List<MatchModel> matches;           // del giocatore, data crescente
    final int totalGames, votedGames, totalGoals, wins, draws, losses,
        participationPct, bestUnbeaten, gamesWithGoal;
    final double avgVote, bestVote, worstVote, avgGoals;
    final double? modeVote;
    final String currentStreak;               // es. '3V', '—' se nessuna partita
    final List<VotePoint> votePoints;
    final List<int> goalsPerMatch;            // allineata a matches
    final List<int> cumulativeGoals;          // allineata a matches
    final Map<String, int> matchesByMonth;    // chiave 'yyyy-MM'
    final Map<String, int> goalsByMonth;
    final Map<String, double> avgVoteByMonth;
    final Map<String, int> voteDistribution;  // chiavi '1-2','3-4','5-6','7-8','9-10'
    final List<VotePoint> movingAvgVotes;     // finestra 5, matchIndex dell'ultimo voto della finestra
    final List<({int matchIndex, double pct})> rollingWinRate; // finestra 5
    final List<RecentResult> recentResults;   // ultime 10
    final Map<MatchOutcome, List<double>> votesByOutcome;
    MatchOutcome outcomeOf(MatchModel m);     // risultato dal punto di vista del giocatore
    int goalsForOf(MatchModel m);
    int goalsAgainstOf(MatchModel m);
  }
  ```
  Costanti pubbliche: `PlayerStatsSummary.movingWindow = 5`, `PlayerStatsSummary.recentCount = 10`.

- [ ] **Step 1: Creare il branch**

Run: `git switch -c feature/player-stats-tabs`

- [ ] **Step 2: Scrivere i test che falliscono**

Helper in testa al file (usato anche dai task successivi):

```dart
MatchModel m(String id, DateTime date,
        {List<String> a = const ['p1', 'x'], List<String> b = const ['y', 'z'],
         int sa = 0, int sb = 0, Map<String, double>? votes,
         Map<String, int>? goals, String mvp = ''}) =>
    MatchModel(id: id, date: date, teamA: a, teamB: b, scoreA: sa, scoreB: sb,
        votes: votes, goals: goals, fieldLocation: 'f1', mvp: mvp, hustlePlayer: '');
```

Test (`group('existing stats')`):
- `'empty match list yields zeros and no crash'` — `compute(playerId: 'p1', allMatches: [])`: `totalGames == 0`, `avgVote == 0.0`, `modeVote == null`, `currentStreak == '—'`, `participationPct == 0`.
- `'ignores matches the player did not play and sorts by date'` — 3 partite di cui una senza `p1`, passate in ordine decrescente: `totalGames == 2`, `matches.first.date` è la più vecchia, `participationPct == 67`.
- `'counts W/D/L from both sides'` — `p1` in teamA 3-1, in teamB 2-2, in teamB con sa=4 sb=0: `wins == 1, draws == 1, losses == 1`.
- `'current streak and best unbeaten'` — sequenza V, V, S, P, V, V, V: `currentStreak == '3V'`, `bestUnbeaten == 4`.
- `'vote aggregates'` — voti 6, 8, 8, (nessun voto), 5: `votedGames == 4`, `avgVote == 6.75`, `bestVote == 8`, `worstVote == 5`, `modeVote == 8`, `votePoints.map((p) => p.matchIndex) == [0,1,2,4]`, `voteDistribution['7-8'] == 2`, `voteDistribution['5-6'] == 2`.
- `'matches with no votes at all do not crash'` — 3 partite senza voti: `votedGames == 0`, `bestVote == 0.0`, `movingAvgVotes` vuota.
- `'goals and monthly maps'` — gol 2, 0, 1 in gen, gen, feb 2026: `totalGoals == 3`, `gamesWithGoal == 2`, `cumulativeGoals == [2,2,3]`, `goalsByMonth == {'2026-01': 2, '2026-02': 1}`, `matchesByMonth == {'2026-01': 2, '2026-02': 1}`.
- `'rolling windows need 5 entries'` — 6 partite (V,V,S,V,S,V) con voti 6,7,8,9,10,10: `rollingWinRate.length == 2`, `rollingWinRate.first.pct == 60`, `movingAvgVotes.length == 2`.
- `'recent results keep the last 10'` — 12 partite: `recentResults.length == 10`, `recentResults.first.date == matches[2].date`.

- [ ] **Step 3: Verificare che falliscano**

Run: `flutter test test/services/player_stats_summary_test.dart`
Expected: FAIL — `player_stats_summary.dart` non esiste.

- [ ] **Step 4: Implementare `PlayerStatsSummary.compute`**

Spostare la logica di `lib/screens/player_stats_screen.dart:24-283` senza cambiarne la semantica, sostituendo le ripetizioni `inTeamA ? scoreA : scoreB` con `goalsForOf`/`goalsAgainstOf`/`outcomeOf`. `participationPct` usa `allMatches.length` come denominatore (oggi `data.matchCount`, stesso valore). Ogni `reduce` è protetto da un controllo di lista vuota.

- [ ] **Step 5: Verificare che passino**

Run: `flutter test test/services/player_stats_summary_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/services/player_stats_summary.dart test/services/player_stats_summary_test.dart
git commit -m "feat(stats): extract PlayerStatsSummary from player stats screen"
```

---

### Task 2: Guscio a tab e spostamento delle sezioni esistenti

**Files:**
- Modify: `lib/screens/player_stats_screen.dart` (diventa guscio + `part`)
- Create: `lib/screens/player_stats/stats_widgets.dart`, `overview_tab.dart`, `votes_tab.dart`, `goals_tab.dart`, `results_tab.dart`, `records_tab.dart`, `teammates_tab.dart`, `seasons_tab.dart` (tutti `part of '../player_stats_screen.dart';`)
- Test: `test/screens/player_stats_screen_test.dart`

**Interfaces:**
- Consumes: `PlayerStatsSummary` (Task 1).
- Produces: ogni tab è `class _XxxTab extends StatelessWidget` con costruttore `const _XxxTab({required this.player, required this.summary})` (`PlayerModel player`, `PlayerStatsSummary summary`). Widget `_EmptyTab()` in `stats_widgets.dart` con il testo `Dati insufficienti per questa categoria`. Helper `List<Widget> _section(String title, Color accent, Widget child)` in `stats_widgets.dart` che restituisce `[FifaSectionHeader(title, accent: accent), child, SizedBox(height: 24)]`.

- [ ] **Step 1: Scrivere il widget test che fallisce**

Setup Hive come in `test/services/data_service_lookup_test.dart`; `pumpWidget(MaterialApp(home: ChangeNotifierProvider<DataService>.value(value: dataService, child: PlayerStatsScreen(player: mario))))`. Inizializzare `initializeDateFormatting('it_IT')` in `setUpAll`.

Test:
- `'shows the empty message and no tabs when the player has no matches'` — `find.text('Nessuna partita registrata per questo giocatore.')` una volta; `find.byType(TabBar)` nessuno.
- `'shows the 7 tabs in order'` — con 6 partite di `p1` (voti e gol presenti): `find.byType(Tab)` → 7; testi `PANORAMICA`, `VOTI`, `GOL`, `RISULTATI`, `RECORD`, `COMPAGNI`, `STAGIONI`.
- `'tapping VOTI shows the vote trend section'` — tap su `VOTI`, `pumpAndSettle`, `find.text('ANDAMENTO VOTI')` trovato.
- `'votes tab shows the insufficient-data message when no match has a vote'` — partite senza voti, tap `VOTI` → `find.text('DATI INSUFFICIENTI PER QUESTA CATEGORIA')` (`_EmptyTab` usa `FifaLabel`, che mette in maiuscolo).
- `'compact header shows games and average vote'` — `find.textContaining('6 partite')` trovato.

- [ ] **Step 2: Verificare che falliscano**

Run: `flutter test test/screens/player_stats_screen_test.dart`
Expected: FAIL — nessun `TabBar`.

- [ ] **Step 3: Implementare il guscio**

`PlayerStatsScreen.build`: legge `DataService` (`listen: false`), chiama `PlayerStatsSummary.compute(playerId: player.id, allMatches: data.getAllMatches())`. Se `summary.totalGames == 0` → `Scaffold` con il messaggio attuale. Altrimenti `DefaultTabController(length: 7)` → `Scaffold` con `AppBar(title: FifaLabel(player.name), bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, indicatorColor: AppTheme.accentGreen, ...))` e `body: Column([_CompactHeader(player, summary), Expanded(TabBarView(...))])`. `_CompactHeader`: avatar (`radius: 22`), nome, `FifaBadge(role)`, `'${totalGames} partite · ${avgVote.toStringAsFixed(1)} ⭐'`.

- [ ] **Step 4: Spostare le sezioni nelle tab**

Ogni tab è una `ListView(padding: EdgeInsets.fromLTRB(16, 12, 16, 32))`; se la lista di sezioni visibili è vuota restituisce `_EmptyTab()`. Spostamenti (righe dell'attuale file):

| Tab | Blocchi da spostare |
|---|---|
| Overview | riquadri 353–457, Radar 1369–1383, Form Recente 1583–1709 |
| Votes | 458–586, 895–1013, 1014–1128, 1219–1368, 1426–1438 (+ `_ConsistencyCard`), 1439–1582 |
| Goals | 587–697, 1129–1218, 1710–1822 |
| Results | 698–780, 1823–1950, 1385–1391 (+ `_FieldStatsCard`, `_FieldStat`, `_FieldMetric`) |
| Records | 1412–1424 (+ `_MilestonesCard`) |
| Teammates | 1392–1411 |
| Seasons | 781–894 |

L'header giocatore 306–352 e il messaggio 1951–1974 si eliminano (sostituiti da `_CompactHeader` e `_EmptyTab`). Le variabili locali usate nei blocchi diventano campi di `summary`; `FlSpot` si costruiscono nella tab da `votePoints`/`goalsPerMatch`/ecc. Le etichette data dei grafici usano `formatShortDate(summary.matches[i].date)`. `_RecentResult` è sostituito dal record `RecentResult`.

- [ ] **Step 5: Verificare test e lint**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` e tutti i test PASS.

- [ ] **Step 6: Verifica manuale**

Run: `flutter run` sul simulatore; aprire un giocatore reale e confrontare i 12 riquadri della Panoramica con la versione su `main` (stessi valori). Annotare l'esito nel messaggio di commit o nel report del task.

- [ ] **Step 7: Commit**

```bash
git add lib/screens/player_stats_screen.dart lib/screens/player_stats test/screens/player_stats_screen_test.dart
git commit -m "refactor(stats): split player stats screen into 7 tabs"
```

---

### Task 3: Voti → Voto relativo

**Files:**
- Modify: `lib/services/player_stats_summary.dart`, `lib/screens/player_stats/votes_tab.dart`
- Test: `test/services/player_stats_summary_test.dart`, `test/screens/player_stats_screen_test.dart`

**Interfaces:**
- Produces sul summary:
  ```dart
  final List<({DateTime date, double delta})> relativeVotes; // cronologico, tutte le partite valide
  final double avgRelativeVote;   // 0.0 se nessuna
  final int aboveAvgPct;          // % arrotondata di delta > 0; 0 se nessuna
  ```

- [ ] **Step 1: Test che falliscono** (`group('relative vote')`)
- `'delta is vote minus the mean of every other voted player in the match'` — partita: p1=8, x=6, y=7, z (nessun voto) → `relativeVotes.single.delta == 1.5`.
- `'skips matches where p1 has no vote or nobody else voted'` — una partita con solo p1 votato, una senza voto p1 → `relativeVotes` vuota, `avgRelativeVote == 0.0`.
- `'average and above-average percentage'` — delta +1, −0.5, +2 → `avgRelativeVote ≈ 0.8333` (`closeTo(0.833, 0.001)`), `aboveAvgPct == 67`.
- Widget: `'votes tab shows relative vote card'` — tap `VOTI`, scroll fino a `find.text('VOTO RELATIVO')` → trovato.

- [ ] **Step 2: Verificare che falliscano** — `flutter test test/services/player_stats_summary_test.dart` → FAIL (getter mancanti).

- [ ] **Step 3: Implementare** i campi nel summary e `_RelativeVoteCard` in `votes_tab.dart`, sezione `'Voto Relativo'` (accent `AppTheme.accentBlue`), visibile se `relativeVotes.length >= 2`. Contenuto: due `_StatBox` (`'DELTA MEDIO'` con segno, es. `+0.4`; `'SOPRA MEDIA'` → `'$aboveAvgPct%'`) e un `BarChart` delle ultime 20 voci: `BarChartRodData(toY: delta)`, colore `AppTheme.accentGreen` se `delta > 0` altrimenti `AppTheme.accentRed`, `minY`/`maxY` simmetrici su `max(|delta|)` arrotondato per eccesso a 0.5.

- [ ] **Step 4: Verificare** — `flutter analyze && flutter test` → PASS.

- [ ] **Step 5: Commit** — `git commit -am "feat(stats): relative vote in votes tab"`

---

### Task 4: Gol → Quota gol squadra, Doppiette e triplette

**Files:**
- Modify: `lib/services/player_stats_summary.dart`, `lib/screens/player_stats/goals_tab.dart`
- Test: come Task 3.

**Interfaces:**
- Produces:
  ```dart
  final int teamGoals;           // somma di goalsForOf(m) sulle partite del giocatore
  final double? teamGoalShare;   // totalGoals / teamGoals; null se teamGoals == 0
  final int braces;              // partite con esattamente 2 gol
  final int hatTricks;           // partite con >= 3 gol
  final ({int goals, DateTime date})? maxGoalsMatch; // null se totalGoals == 0; pari merito → più recente
  ```

- [ ] **Step 1: Test che falliscono** (`group('goals extras')`)
- `'team goal share uses the team score as denominator'` — p1 segna 1 su 3 (sa=3) e 2 su 2 (in teamB, sb=2), mappa `goals` incompleta per gli altri → `teamGoals == 5`, `teamGoalShare == closeTo(0.6, 1e-9)`.
- `'share is null when the team never scores'` — due 0-0 → `teamGoalShare == null`.
- `'braces, hat tricks and max goals'` — gol 2, 3, 0, 4, 2 → `braces == 2`, `hatTricks == 2`, `maxGoalsMatch!.goals == 4`.
- `'max goals tie picks the most recent'` — gol 3 il 1/1 e 3 il 1/2 → `maxGoalsMatch!.date == DateTime(2026, 2, 1)`.
- Widget: tap `GOL` → `find.text('QUOTA GOL SQUADRA')` trovato.

- [ ] **Step 2: Verificare che falliscano** → FAIL.

- [ ] **Step 3: Implementare** campi + due sezioni in `goals_tab.dart`:
  - `'Quota Gol Squadra'` (accent `AppTheme.accentRed`), visibile se `teamGoalShare != null`: `PieChart` a ciambella (`centerSpaceRadius: 48`, due sezioni: giocatore `accentRed`, resto `AppTheme.surfaceAlt`), al centro `'${(share*100).round()}%'`, sotto `'$totalGoals gol su $teamGoals della squadra'`.
  - `'Doppiette e Triplette'` (accent `AppTheme.accentGold`), visibile se `totalGoals > 0`: tre `_StatBox` — `'DOPPIETTE'`, `'TRIPLETTE+'`, `'MAX GOL'` con sottotitolo `formatShortDate(maxGoalsMatch.date)`.

- [ ] **Step 4: Verificare** — `flutter analyze && flutter test` → PASS.

- [ ] **Step 5: Commit** — `git commit -am "feat(stats): team goal share and multi-goal games"`

---

### Task 5: Risultati → Differenza reti media, Margini

**Files:**
- Modify: `lib/services/player_stats_summary.dart`, `lib/screens/player_stats/results_tab.dart`
- Test: come Task 3.

**Interfaces:**
- Produces:
  ```dart
  enum MarginBand { narrow, clear, wide }   // |margine| 1, 2, >=3 — etichette 'Di misura', 'Nette', 'Larghe'
  final double avgGoalDiff, avgGoalsFor, avgGoalsAgainst;  // 0.0 se nessuna partita
  final Map<MarginBand, int> winsByMargin;   // sempre con tutte e 3 le chiavi
  final Map<MarginBand, int> lossesByMargin; // idem
  ```

- [ ] **Step 1: Test che falliscono** (`group('results extras')`)
- `'average goal difference from the player side'` — 5-2 in teamA, 1-3 in teamB (p1 vince 3-1), 0-0 → `avgGoalDiff == closeTo(5/3, 1e-9)`, `avgGoalsFor == 8/3`, `avgGoalsAgainst == 1.0`.
- `'margin bands'` — vittorie con margine 1, 2, 3, 6 e sconfitte con margine 1, 1, 4 → `winsByMargin == {narrow: 1, clear: 1, wide: 2}`, `lossesByMargin == {narrow: 2, clear: 0, wide: 1}`.
- `'only draws → all bands zero'` — due 2-2 → entrambe le mappe a zero, `avgGoalDiff == 0.0`.
- Widget: tap `RISULTATI` → `find.text('MARGINI')` trovato.

- [ ] **Step 2: Verificare che falliscano** → FAIL.

- [ ] **Step 3: Implementare** campi + sezioni:
  - `'Differenza Reti'` (accent `AppTheme.accentGreen`): `_StatBox` `'DIFF. MEDIA'` con segno (`+1.3`, `0.0`, `-0.5`), `_StatBox` `'GF / PARTITA'`, `_StatBox` `'GS / PARTITA'`, una cifra decimale.
  - `'Margini'` (accent `AppTheme.accentBlue`): una riga per `MarginBand`; etichetta al centro, barra verde verso destra (vittorie) e rossa verso sinistra (sconfitte), larghezza proporzionale al massimo conteggio tra le 6 celle (con `Row` + `FractionallySizedBox`, niente fl_chart); conteggi scritti alle estremità; sotto `'Pareggi: $draws'`.

- [ ] **Step 4: Verificare** — `flutter analyze && flutter test` → PASS.

- [ ] **Step 5: Commit** — `git commit -am "feat(stats): goal difference and win/loss margins"`

---

### Task 6: Record → Serie record, Miglior partita

**Files:**
- Modify: `lib/services/player_stats_summary.dart`, `lib/screens/player_stats/records_tab.dart`
- Test: come Task 3.

**Interfaces:**
- Produces:
  ```dart
  typedef Streak = ({int length, DateTime start, DateTime end});
  final Streak? longestWinStreak, longestUnbeatenStreak, longestLossStreak, longestScoringStreak; // null se length 0
  final MatchModel? bestVoteMatch;   // voto più alto; pari → più gol; pari → più recente
  final MatchModel? mostGoalsMatch;  // più gol (>0); pari → voto più alto (assente = -inf); pari → più recente
  ```
  `longestUnbeatenStreak!.length` deve coincidere con `bestUnbeaten` (Task 1).

- [ ] **Step 1: Test che falliscono** (`group('records')`)
- `'longest streaks with dates'` — esiti V,V,S,V,V,V,P,S,S con gol 1,1,0,1,0,0,2,1,1 → win 3 (start = 4ª partita, end = 6ª), unbeaten 4 (4ª→7ª), loss 2 (8ª→9ª), scoring 3 (7ª→9ª).
- `'ties pick the most recent streak'` — V,V,S,V,V → `longestWinStreak!.start == date della 4ª`.
- `'single match gives length-1 streaks with start == end'` — una vittoria con gol → win e scoring `length 1`, `start == end`; `longestLossStreak == null`.
- `'best vote match tie-breaks on goals then recency'` — voti 8 (1 gol), 8 (2 gol), 7 → id della seconda; altra fixture con 8/1 gol e 8/1 gol → la più recente.
- `'most goals match is null when the player never scored'`.
- Widget: tap `RECORD` → `find.text('SERIE RECORD')` e `find.text('TRAGUARDI IN CARRIERA')` trovati; tap sulla scheda "Voto più alto" apre `MatchDetailScreen` (`find.byType(MatchDetailScreen)`).

- [ ] **Step 2: Verificare che falliscano** → FAIL.

- [ ] **Step 3: Implementare** campi + sezioni:
  - `'Serie Record'` (accent `AppTheme.accentGold`), griglia 2×2 di `_StatBox`: `'VITTORIE'`, `'IMBATTUTO'`, `'SCONFITTE'`, `'A SEGNO'`; valore = length (o `'—'`), sottotitolo `'${formatShortDate(start)} → ${formatShortDate(end)}'` (solo la data se `start == end`).
  - `'Miglior Partita'` (accent `AppTheme.accentGreen`), visibile se almeno una delle due partite è non null: due card tappabili `'VOTO PIÙ ALTO'` / `'PIÙ GOL'` con data, risultato `'${goalsForOf} - ${goalsAgainstOf}'` dal punto di vista del giocatore, campo (`DataService.getFieldById(m.fieldLocation)?.name ?? m.fieldLocation`); `onTap` → `Navigator.push(MaterialPageRoute(builder: (_) => MatchDetailScreen(match: m)))`.
  - `'Traguardi in Carriera'` resta dopo queste due sezioni.

- [ ] **Step 4: Verificare** — `flutter analyze && flutter test` → PASS.

- [ ] **Step 5: Commit** — `git commit -am "feat(stats): record streaks and best matches"`

---

### Task 7: Stagioni → Mappa presenze, Giorno della settimana, Confronto anni

**Files:**
- Modify: `lib/services/player_stats_summary.dart`, `lib/screens/player_stats/seasons_tab.dart`
- Test: come Task 3.

**Interfaces:**
- Produces:
  ```dart
  /// chiave = DateTime.utc(y, m, d); valore = esito dell'ultima partita (per orario) del giorno
  final Map<DateTime, MatchOutcome> outcomeByDay;
  final List<int> activeYears;   // crescente
  final List<({int weekday, int games, int winPct, double? avgVote})> weekdayStats; // solo giorni con partite, lun→dom (DateTime.monday..sunday)
  final List<({int year, int games, double? avgVote, int goals, double goalsPerGame, int winPct, int mvps})> yearStats; // anno decrescente
  ```
  Funzione pura top-level nello stesso file: `List<DateTime> heatmapDays(int year)` — tutti i giorni da lunedì della settimana che contiene l'1/1 a domenica della settimana che contiene il 31/12, come `DateTime.utc`.

- [ ] **Step 1: Test che falliscono** (`group('seasons')`)
- `'outcomeByDay keeps the last match of the day'` — stesso giorno ore 18 (V) e 21 (S) → `outcomeByDay[DateTime.utc(2026,3,10)] == MatchOutcome.loss`, `outcomeByDay.length == 1`.
- `'heatmapDays covers whole weeks without DST gaps'` — `heatmapDays(2026)`: primo elemento è lunedì 29/12/2025, ultimo domenica 3/1/2027, `length % 7 == 0`, nessun duplicato (`toSet().length == length`), contiene `DateTime.utc(2026,3,29)` e `DateTime.utc(2026,10,25)`.
- `'weekday stats'` — 2 partite di martedì (V con voto 7, S con voto 5), 1 di sabato (P, senza voto) → due voci; martedì `games 2, winPct 50, avgVote 6.0`; sabato `avgVote == null`.
- `'year stats newest first with mvp count'` — 2025: 2 partite, 1 MVP; 2026: 1 partita → `yearStats.first.year == 2026`, `yearStats.last.mvps == 1`, `activeYears == [2025, 2026]`.
- Widget: tap `STAGIONI` → `find.text('MAPPA PRESENZE')` trovato; con partite in un solo anno `find.text('CONFRONTO ANNI')` assente.

- [ ] **Step 2: Verificare che falliscano** → FAIL.

- [ ] **Step 3: Implementare** campi + sezioni (ordine nella tab: Mappa presenze, Giorno della settimana, Confronto anni, Partite per mese):
  - `'Mappa Presenze'` (accent `AppTheme.accentGreen`), `_ActivityHeatmap` stateful: chip `ChoiceChip` per ogni `activeYears`; default anno corrente se presente, altrimenti l'ultimo. Griglia di colonne-settimana da 7 celle 12×12 (gap 3) dentro uno `SingleChildScrollView(scrollDirection: Axis.horizontal)` con `ScrollController`; dopo il primo frame `jumpTo` la colonna della settimana corrente (anno corrente) o l'ultima. Colori: V `accentGreen`, P `accentGold`, S `accentRed`, nessuna partita `AppTheme.surfaceAlt`; giorni fuori dall'anno trasparenti. Legenda V/P/S sotto.
  - `'Giorno della Settimana'` (accent `AppTheme.accentBlue`): `BarChart` con una barra per voce di `weekdayStats` (altezza = games), etichetta asse `'LUN'…'DOM'`, sotto ogni barra `'$winPct% V'` e `avgVote?.toStringAsFixed(1) ?? '—'`.
  - `'Confronto Anni'` (accent `AppTheme.accentGold`), visibile se `yearStats.length >= 2`: tabella con colonne `ANNO | PART. | VOTO | GOL | G/P | %V | MVP`; ogni cella numerica (non l'anno) ha `▲` verde / `▼` rossa se diversa dall'anno precedente (riga sotto), nulla se uguale o se è l'anno più vecchio; `avgVote == null` → `'—'` e nessuna freccia.

- [ ] **Step 4: Verificare** — `flutter analyze && flutter test` → PASS.

- [ ] **Step 5: Verifica manuale** — `flutter run`, aprire un giocatore reale, scorrere tutte e 7 le tab; controllare che la mappa presenze si apra sulla settimana corrente e che nessuna tab richieda più di ~3 schermate di scroll.

- [ ] **Step 6: Commit** — `git commit -am "feat(stats): seasons tab with heatmap, weekday and year comparison"`
