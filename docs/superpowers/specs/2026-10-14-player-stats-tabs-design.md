# Statistiche giocatore divise in tab — Design

Data: 2026-10-14
Stato: in revisione

## Obiettivo

Oggi la schermata del dettaglio giocatore ([`lib/screens/player_stats_screen.dart`](../../../lib/screens/player_stats_screen.dart),
circa 3.160 righe) mostra circa 25 sezioni in un'unica lista verticale. È così lunga che
quasi nessuno la scorre fino in fondo.

Cosa vogliamo ottenere:

1. Dividere le statistiche in **tab per categoria**, così ogni schermata è breve e
   qualsiasi statistica si raggiunge con uno o due tocchi.
2. Aggiungere tre gruppi di **statistiche nuove**: *serie e record*, *impatto e voto
   relativo*, *tempo e stagioni*. Tutte devono essere calcolabili con i dati che l'app
   salva già.

### Vincoli

- **Nessuna modifica ai modelli Hive** (`MatchModel`, `PlayerModel`) e nessuna migrazione.
- La schermata resta nel **livello legacy** (`lib/screens/` + `DataService`). Non si
  migra in `lib/features/` (vedi AGENTS.md).
- Le sezioni esistenti si **spostano senza cambiarle**: stessi grafici e stessi calcoli.

### Fuori ambito

- Il gruppo "Fase difensiva": l'abbiamo valutato e scartato.
- Il confronto tra due giocatori.
- Modifiche alla classifica (`StatsScreen`).

### Criteri di successo

- Ogni tab sta in poche schermate di scroll.
- Le statistiche esistenti mostrano gli stessi valori di prima.
- I calcoli nuovi hanno test unitari.

## Approccio scelto

**A — una schermata con le tab, un file per ogni tab, calcoli separati dalla grafica.**
Le alternative scartate sono due. Mettere le tab dentro il file attuale (B) lo porterebbe
oltre le 4.000 righe senza calcoli testabili. Migrarla in `features/` (C) vorrebbe dire
troppa struttura finché il resto delle statistiche legge da `DataService`. Partire da A
lascia comunque aperta la strada verso C, perché i calcoli saranno già isolati.

## Architettura

```
lib/services/player_stats_summary.dart      ← calcoli puri (niente Flutter/Hive/fl_chart)
lib/screens/player_stats_screen.dart        ← guscio: intestazione + TabBar + TabBarView
lib/screens/player_stats/
    stats_widgets.dart                      ← widget condivisi (_StatBox, _ChartCard, _LegendRow, …)
    overview_tab.dart
    votes_tab.dart
    goals_tab.dart
    results_tab.dart
    records_tab.dart                        ← nuova
    teammates_tab.dart
    seasons_tab.dart                        ← nuova
```

### Flusso dei dati

1. `PlayerStatsScreen` legge una volta da `DataService` le partite (tutte e quelle del
   giocatore) e il numero totale di partite.
2. Chiama `PlayerStatsSummary.compute(playerId:, allMatches:)`, che restituisce un
   oggetto immutabile con tutti i valori.
3. Il guscio passa il summary, il `PlayerModel` e le partite del giocatore a ogni tab.
4. Le tab sono `StatelessWidget` che leggono dal summary e trasformano i dati in grafici:
   la conversione in `FlSpot` avviene nella tab, non nel summary.

Le partite servono ancora alle tab, oltre al summary, perché alcuni widget esistenti
(`_FieldStatsCard`, `_MilestonesCard`, `ChemistryBubbleChart`, `ChemistryRadarChart`)
calcolano da sé i propri dati a partire dalle partite. Restano così come sono.

### `PlayerStatsSummary`

È una classe immutabile con un costruttore statico `compute`. Sostituisce le righe
36–283 dell'attuale `build()`, spostando la logica senza cambiarla, e aggiunge i calcoli
nuovi descritti più sotto. Lavora solo con tipi Dart semplici (`int`, `double`,
`List`, `Map`, `DateTime`) e con `MatchModel`.

Per ogni partita introduce un helper interno per il risultato del giocatore (V/P/S, gol
fatti e subiti dalla sua squadra), al posto delle 7 ripetizioni attuali di
`inTeamA ? scoreA : scoreB`.

### Guscio della schermata

- `DefaultTabController` con 7 tab e una `TabBar` scorrevole (`isScrollable: true`).
- Sopra le tab c'è un'**intestazione compatta e fissa**: avatar, nome, ruolo, partite
  giocate e voto medio. I riquadri riassuntivi completi si spostano nella tab
  Panoramica.
- Ogni tab è una `ListView` con il padding attuale (`16, 12, 16, 32`).
- Se il giocatore non ha partite, compare lo stesso messaggio di oggi ("Nessuna partita
  registrata…") e non vengono mostrate le tab.
- Se una sezione non ha abbastanza dati, resta nascosta come oggi (per esempio la media
  mobile richiede almeno 5 voti). Se un'intera tab resta vuota, mostra il messaggio
  "Dati insufficienti per questa categoria".

## Contenuto delle tab

| Tab | Sezioni esistenti spostate | Sezioni nuove |
|---|---|---|
| **Panoramica** | 12 riquadri riassuntivi (Partite, Voto medio, Gol totali, Miglior/Peggior voto, MVP, Media gol, Partite gol, Partecipaz., Striscia, Imbattuto, Voto modale), Radar Performance, Form Recente | — |
| **Voti** | Andamento Voti, Distribuzione Voti, Voto Medio per Mese, Voto per Risultato, Consistenza, Trend Voto (Media Mobile) | Voto relativo |
| **Gol** | Gol per Partita, Gol Cumulativi, Gol per Mese | Quota gol squadra, Doppiette e triplette |
| **Risultati** | Risultati (torta V/P/S), Win-Rate rolling, Statistiche per Campo | Differenza reti media, Margini di vittoria e sconfitta |
| **Record** | Traguardi in Carriera | Serie record, Miglior partita |
| **Compagni** | Chemistry con i Compagni, Radar Chemistry | — |
| **Stagioni** | Partite per Mese | Mappa presenze, Giorno della settimana, Confronto anni |

## Statistiche nuove: definizioni

In tutto il documento valgono queste convenzioni:

- Per "partite del giocatore" si intendono quelle in cui compare in `teamA` o in `teamB`,
  ordinate per data crescente.
- **Gol fatti** e **gol subiti** sono il punteggio della sua squadra e quello avversario
  (`scoreA`/`scoreB`).
- **Margine** = gol fatti − gol subiti.

### Voti → Voto relativo

Serve a capire se il giocatore va meglio o peggio degli altri nella stessa partita.

- **Calcolo per partita**: si considerano solo le partite in cui il giocatore ha un voto
  e almeno un altro giocatore ha un voto. `delta = voto del giocatore − media dei voti
  di tutti gli altri giocatori votati in quella partita` (entrambe le squadre).
- **Valori mostrati**: delta medio (con il segno, es. `+0.4`) e percentuale di partite
  sopra la media (`delta > 0`).
- **Grafico**: barre per partita sulle ultime 20 partite valide, verdi se il delta è
  positivo e rosse se è negativo, con lo zero al centro.
- **Visibile** se ci sono almeno 2 partite valide.

### Gol → Quota gol squadra

Indica quanta parte dei gol della squadra segna il giocatore.

- **Calcolo**: `somma dei gol del giocatore / somma dei gol fatti dalla sua squadra`,
  sulle partite del giocatore. Il denominatore è il punteggio della squadra e non la
  somma della mappa `goals`, che potrebbe essere incompleta.
- **Visualizzazione**: una ciambella con la percentuale al centro e la didascalia
  "X gol su Y della squadra".
- **Visibile** se la squadra ha segnato almeno 1 gol.

### Gol → Doppiette e triplette

- **Doppiette**: partite con esattamente 2 gol del giocatore.
- **Triplette+**: partite con 3 o più gol.
- **Visualizzazione**: due riquadri con il conteggio, più "Max gol in una partita" con
  la data.
- **Visibile** se il giocatore ha segnato almeno una volta.

### Risultati → Differenza reti media

- **Calcolo**: media dei margini sulle partite del giocatore.
- **Visualizzazione**: un riquadro con il segno (es. `+1.3`) e accanto la media dei gol
  fatti e dei gol subiti dalla squadra.

### Risultati → Margini di vittoria e sconfitta

Mostra se vince e perde di poco o di tanto.

- **Classificazione**: le vittorie si dividono per margine in *di misura* (1),
  *nette* (2) e *larghe* (≥3). Le sconfitte si dividono allo stesso modo usando il
  valore assoluto del margine.
- **Grafico**: barre orizzontali contrapposte, con le vittorie a destra in verde e le
  sconfitte a sinistra in rosso, una riga per categoria. I pareggi compaiono come
  conteggio a parte.

### Record → Serie record

Quattro riquadri, ciascuno con il valore e le date di inizio e fine della serie:

- **Serie di vittorie più lunga**.
- **Serie senza sconfitte più lunga**. Il valore c'è già come "Imbattuto" e qui si
  aggiungono le date.
- **Serie di sconfitte più lunga**.
- **Partite di fila a segno più lunga**: partite consecutive del giocatore con almeno
  1 gol.

A parità di lunghezza conta la serie più recente.

### Record → Miglior partita

Due schede, ciascuna con data, risultato e campo. Toccandole si apre il
`MatchDetailScreen`.

- **Voto più alto**: a parità di voto vince la partita con più gol, poi la più recente.
- **Più gol segnati**: a parità di gol vince la partita con il voto più alto, poi la
  più recente.

### Stagioni → Mappa presenze

- **Contenuto**: una griglia stile "contributi" con colonne = settimane e righe =
  lun…dom, per l'anno selezionato.
- **Colori**: quadratino verde, oro o rosso a seconda del risultato (V/P/S), grigio
  tenue se quel giorno non ha giocato. Se nello stesso giorno ci sono più partite, conta
  l'ultima.
- **Anno**: si sceglie con dei chip tra gli anni in cui ha giocato. Di default è l'anno
  corrente, se presente, altrimenti il più recente.
- **Scorrimento**: in orizzontale dentro la card. All'apertura la griglia si posiziona
  sulla settimana corrente (o sull'ultima dell'anno).

### Stagioni → Giorno della settimana

- **Valori**: per ogni giorno da lunedì a domenica con almeno una partita, numero di
  partite, percentuale di vittorie e voto medio.
- **Visualizzazione**: barre per numero di partite, con percentuale di vittorie e voto
  medio scritti sotto ogni barra.

### Stagioni → Confronto anni

- **Righe**: una per ogni anno con partite, dal più recente.
- **Colonne**: partite, voto medio, gol, gol a partita, % vittorie, MVP (partite con
  `match.mvp == playerId`).
- **Tendenza**: ogni cella ha una freccia ▲▼ rispetto all'anno precedente. Il primo
  anno non ha frecce.
- **Visibile** solo se ci sono almeno 2 anni.

## Errori e casi limite

- Il summary non lancia eccezioni. Con liste vuote restituisce zeri, liste vuote o
  `null` per i valori facoltativi (es. miglior partita).
- Non si divide mai per zero: ogni media protegge il denominatore.
- I voti sono `double` da 1 a 10; si considerano solo quelli presenti nella mappa
  `votes`, come oggi.

## Test

- **Unità** — `test/services/player_stats_summary_test.dart`, con liste di `MatchModel`
  costruite a mano e senza Hive. Coprono:
  - i valori esistenti spostati: V/P/S, voto medio, striscia, imbattuto, voto modale,
    distribuzione;
  - ogni statistica nuova, compresi i casi limite: nessun voto, una sola partita,
    pari merito, partite nello stesso giorno, squadra che non segna.
- **Widget** — `test/screens/player_stats_screen_test.dart`:
  - le 7 tab sono presenti;
  - toccando una tab compare l'intestazione di una sua sezione;
  - con 0 partite compare il messaggio vuoto.

  Il test fornisce un `DataService` tramite `Provider`. Se `DataService` richiede Hive,
  si seguono le convenzioni Hive di AGENTS.md (cartella temporanea, box assegnati
  direttamente).
- **Verifica manuale**: avviare l'app e confrontare i valori della Panoramica con la
  versione attuale su un giocatore reale.

## Ordine di lavoro suggerito

1. Estrarre `PlayerStatsSummary` con i soli calcoli esistenti e aggiungere i test.
2. Creare il guscio con le tab e spostare le sezioni esistenti nei file delle tab, senza
   cambiarne il comportamento.
3. Aggiungere le statistiche nuove, una tab alla volta, ciascuna con i suoi test.
