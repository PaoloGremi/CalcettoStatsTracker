import 'dart:convert';

import 'package:intl/intl.dart';

import '../models/match_model.dart';

/// Dati anagrafici e di carriera di un giocatore passati al prompt della
/// cronaca. Tenuti separati da `PlayerModel` così prompt e parsing restano
/// funzioni pure, testabili senza Hive.
class ChroniclePlayer {
  final String name;
  final String role;

  /// Totali di carriera, partita corrente inclusa.
  final int careerGoals;
  final int careerMvp;

  const ChroniclePlayer({
    required this.name,
    this.role = '',
    this.careerGoals = 0,
    this.careerMvp = 0,
  });
}

/// Contenuto della cronaca restituito dall'AI, già validato.
class ChronicleResult {
  final String headline;
  final String subheadline;
  final String articleBody;

  /// playerId → giudizio stile Gazzetta.
  final Map<String, String> pagelle;

  const ChronicleResult({
    required this.headline,
    required this.subheadline,
    required this.articleBody,
    required this.pagelle,
  });
}

/// Costruisce il prompt per la "Cronaca Testuale AI" con tutti i dati
/// registrati della partita. [players] è indicizzata per id; un id assente
/// viene mostrato con l'id stesso come nome (come `resolvePlayerName`).
String buildChroniclePrompt(
  MatchModel m, {
  required Map<String, ChroniclePlayer> players,
  required String fieldName,
}) {
  String resultLabel() {
    if (m.scoreA > m.scoreB) return 'Vittoria Bianchi';
    if (m.scoreB > m.scoreA) return 'Vittoria Colorati';
    return 'Pareggio';
  }

  String teamSection(List<String> ids) {
    if (ids.isEmpty) return '  (nessun giocatore registrato)';
    return ids.map((id) {
      final p = players[id];
      final name = p?.name ?? id;
      final role = (p?.role ?? '').isNotEmpty ? ' ruolo:"${p!.role}"' : '';
      final voto = m.votes[id] ?? 0.0;
      final gol = m.goals[id] ?? 0;
      final commento = m.comments[id] ?? '';
      final isMvp = m.mvp == id ? ' [MVP]' : '';
      final isHustle = m.hustlePlayer == id ? ' [COMBATTIVO]' : '';
      final isBG = m.bestGoalPlayer == id ? ' [BEST GOAL]' : '';
      final career = p == null
          ? ''
          : ' carriera:{gol_totali:${p.careerGoals}, mvp_totali:${p.careerMvp}}';
      return '  - id:"$id" nome:"$name"$role$isMvp$isHustle$isBG'
          ' voto:${voto > 0 ? voto.toStringAsFixed(1) : "N/D"}'
          ' gol:$gol'
          '${commento.isNotEmpty ? ' commento_originale:"$commento"' : ""}'
          '$career';
    }).join('\n');
  }

  final goalsA = m.teamA.fold<int>(0, (s, id) => s + (m.goals[id] ?? 0));
  final goalsB = m.teamB.fold<int>(0, (s, id) => s + (m.goals[id] ?? 0));

  return '''
Sei il cronista de "La Gazzetta del Calcetto", stile Gazzetta dello Sport: drammatico, colorito, metafore calcistiche, aggettivi forti. È una partita di calcetto amatoriale tra amici, divisi in due squadre: Bianchi e Colorati.

DATI PARTITA:
- Data: ${DateFormat('EEEE dd MMMM yyyy · HH:mm', 'it_IT').format(m.date)}
- Campo: ${fieldName.isNotEmpty ? fieldName : 'non indicato'}
- Risultato: Bianchi ${m.scoreA} – ${m.scoreB} Colorati
- Esito: ${resultLabel()}
- Gol attribuiti ai singoli: Bianchi $goalsA, Colorati $goalsB

SQUADRA BIANCHI:
${teamSection(m.teamA)}

SQUADRA COLORATI:
${teamSection(m.teamB)}

LEGENDA:
- voto: pagella del gruppo da 1 a 10; N/D = non votato.
- [MVP] = migliore in campo; [COMBATTIVO] = il più grintoso, quello che ha lottato di più; [BEST GOAL] = autore del gol più bello.
- commento_originale: giudizio scritto dal gruppo sul giocatore.
- carriera: totali storici del giocatore, questa partita inclusa.

REGOLE (obbligatorie):
- Usa SOLO i fatti presenti nei dati. Non inventare minuti, ordine dei gol, rimonte, assist, parate, rigori, infortuni, espulsioni o risultati parziali: non sono registrati.
- Attribuisci gol solo a chi ha gol > 0. Se i gol attribuiti sono meno del risultato, non assegnare a nessuno quelli mancanti.
- Non citare giocatori assenti dai dati e scrivi i nomi esattamente come forniti.
- Per chi ha voto N/D non inventare un voto.
- Puoi enfatizzare, usare iperboli e metafore, ma senza contraddire i dati.

Rispondi SOLO con un oggetto JSON valido (nessun testo extra, nessun backtick) con questa struttura:
{
  "headline": "TITOLONE IN MAIUSCOLO MAX 6 PAROLE",
  "subheadline": "Sottotitolo evocativo di 1-2 frasi",
  "articleBody": "Cronaca di 3-4 frasi stile Gazzetta. Cita giocatori per nome, toni epici.",
  "pagelle": {
    "<id_giocatore>": "<giudizio 1 frase stile Gazzetta: mantieni il senso del commento_originale se presente, arricchiscilo con tono giornalistico, cita il voto e i gol se rilevanti>"
  }
}
"pagelle" deve contenere una voce per OGNI giocatore elencato sopra, e le chiavi devono essere esattamente i loro id (il valore del campo id, non il nome).
''';
}

/// Valida e decodifica la risposta dell'AI. Solleva [FormatException] se
/// la risposta non è un oggetto JSON con almeno un titolo.
///
/// Le chiavi di "pagelle" sono ricondotte agli id della partita: se il
/// modello usa il nome del giocatore al posto dell'id viene comunque
/// associato tramite [nameById]; le chiavi non riconducibili sono scartate.
ChronicleResult parseChronicleResponse(
  String raw, {
  required Map<String, String> nameById,
}) {
  final clean = raw
      .trim()
      .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
      .replaceAll(RegExp(r'```\s*$', multiLine: true), '')
      .trim();

  final Object? decoded;
  try {
    decoded = jsonDecode(clean);
  } on FormatException {
    throw const FormatException('Risposta AI non è un JSON valido');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Risposta AI non è un oggetto JSON');
  }

  String str(String key) => (decoded as Map)[key]?.toString().trim() ?? '';

  final headline = str('headline');
  if (headline.isEmpty) {
    throw const FormatException('Risposta AI senza titolo');
  }

  final idByName = {
    for (final e in nameById.entries) e.value.trim().toLowerCase(): e.key,
  };
  final pagelle = <String, String>{};
  final pagelleRaw = decoded['pagelle'];
  if (pagelleRaw is Map) {
    for (final e in pagelleRaw.entries) {
      final key = e.key.toString().trim();
      final text = e.value?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      final id = nameById.containsKey(key) ? key : idByName[key.toLowerCase()];
      if (id != null) pagelle[id] = text;
    }
  }

  return ChronicleResult(
    headline: headline.toUpperCase(),
    subheadline: str('subheadline'),
    articleBody: str('articleBody'),
    pagelle: pagelle,
  );
}
