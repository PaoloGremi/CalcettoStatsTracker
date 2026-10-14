import '../data/hive_boxes.dart';

/// Statistiche FIFA calcolate automaticamente dai dati reali delle partite.
class ComputedFifaStats {
  final int
      vel; // Velocità  → frequenza recente (35%) + gol/partita (40%) + % partite a segno (25%)
  final int tir; // Tiro      → gol/partita + bonus premi MVP/BestGoal
  final int
      pas; // Passaggio → gol compagni (30%) + % vittorie (30%) + presenze (20%) + voto medio (20%)
  final int dri; // Dribbling → gol/partita (40%) + MVP (35%) + voto medio (25%)
  final int
      dif; // Difesa    → gol subiti vs gruppo (35%) + Combattivo (25%) + ruolo (20%) + voto sconfitte (20%)
  final int
      fis; // Fisico    → presenze (30%) + Combattivo (25%) + imbattibilità (20%) + ruolo (15%) + voto medio (10%)

  const ComputedFifaStats({
    required this.vel,
    required this.tir,
    required this.pas,
    required this.dri,
    required this.dif,
    required this.fis,
  });

  /// Overall: media delle 6 stat (arrotondata)
  int get overall => ((vel + tir + pas + dri + dif + fis) / 6).round();

  /// Fallback con stat neutrali (nessuna partita registrata)
  factory ComputedFifaStats.empty() => const ComputedFifaStats(
        vel: 60,
        tir: 60,
        pas: 60,
        dri: 60,
        dif: 60,
        fis: 60,
      );
}

class PlayerStatsCalculator {
  /// Calcola le stat FIFA per un giocatore dato il suo ID.
  ///
  /// ┌─────┬────────────────────────────────────────────────────────────────┐
  /// Soglie tarate sul calcetto (5–8 gol per squadra a partita).
  /// Tutte le stat sono arrotondate e limitate a 40–99.
  ///
  /// ┌─────┬────────────────────────────────────────────────────────────────┐
  /// │ VEL │ 35% Frequenza recente: partite ultimi 60gg / media gruppo      │
  /// │     │ 40% Gol/partita: 0→40, ≥2→99                                   │
  /// │     │ 25% % partite a segno: 0%→40, ≥80%→99                          │
  /// ├─────┼────────────────────────────────────────────────────────────────┤
  /// │ TIR │ Gol/partita (0→40, ≥2→92)                                      │
  /// │     │ + 1 per MVP (max +4) + 2 per BestGoal (max +6) · cap 99        │
  /// ├─────┼────────────────────────────────────────────────────────────────┤
  /// │ PAS │ 30% Gol dei compagni/partita (squadra − propri): 3→40, 8→99    │
  /// │     │ 30% % vittorie: 20%→40, 70%→99                                 │
  /// │     │ 20% Presenze: 0%→40, ≥75%→99                                   │
  /// │     │ 20% Voto medio: 5→40, 8→99                                     │
  /// ├─────┼────────────────────────────────────────────────────────────────┤
  /// │ DRI │ 40% Gol/partita: 0→40, ≥2→99                                   │
  /// │     │ 35% MVP/partita: 0→40, 1 ogni 4 partite→99                     │
  /// │     │ 25% Voto medio: 5→40, 8→99                                     │
  /// ├─────┼────────────────────────────────────────────────────────────────┤
  /// │ DIF │ 35% Gol subiti squadra/partita ÷ media del gruppo:             │
  /// │     │     ≤0.7→99, ≥1.3→40 (gruppo senza gol subiti → neutro)        │
  /// │     │ 25% Premi Combattivo: 0→45, 1 ogni 5 partite→99                │
  /// │     │ 20% Ruolo: D 99 · P 95 · C 75 · A/altro 55                     │
  /// │     │ 20% Voto nelle sconfitte (o medio): 4→40, 8→99                 │
  /// ├─────┼────────────────────────────────────────────────────────────────┤
  /// │ FIS │ Media pesata di 5 componenti (arrotondata):                    │
  /// │     │ 30% Presenze (partiteGiocate / totale sistema): 0%→40, ≥75%→99 │
  /// │     │ 25% Premi Combattivo (rate/partita): 0→45, 1 ogni 5 partite→99 │
  /// │     │ 20% Miglior serie senza sconfitte: 0→40, ≥6→99                 │
  /// │     │ 15% Ruolo: D 99 · P 90 · C 80 · A/altro 65                     │
  /// │     │ 10% Voto medio (impegno): 5→40, 8→99                           │
  /// │     │ Range finale: 40–99                                             │
  /// └─────┴────────────────────────────────────────────────────────────────┘
  static ComputedFifaStats compute(String playerId) {
    final player = HiveBoxes.playersBox.get(playerId);

    // Partite del giocatore ordinate per data (ascending)
    final matches = HiveBoxes.matchesBox.values
        .where((m) => m.teamA.contains(playerId) || m.teamB.contains(playerId))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (matches.isEmpty) return ComputedFifaStats.empty();

    final totalGames = matches.length;
    final totalRegistered = HiveBoxes.matchesBox.length;

    // ── Raccolta dati partita per partita ──────────────────────────────────
    int totalGoals = 0;
    int gamesWithGoal = 0;
    int wins = 0;
    int totalTeamGoals = 0; // gol segnati dalla squadra del giocatore
    int totalConceded = 0; // gol subiti dalla squadra del giocatore
    final allVotes = <double>[];
    final votesInLoss = <double>[];

    // Premi aggregati già sul modello Player
    final mvpCount = player?.mvpCount ?? 0;
    final bestGoalCount = player?.bestGoalCount ?? 0;
    final hustleCount = player?.hustleCount ?? 0;

    for (final m in matches) {
      final inTeamA = m.teamA.contains(playerId);
      final myScore = inTeamA ? m.scoreA : m.scoreB;
      final oppScore = inTeamA ? m.scoreB : m.scoreA;
      final isLoss = myScore < oppScore;

      final goals = m.goals[playerId] ?? 0;
      totalGoals += goals;
      if (goals > 0) gamesWithGoal++;
      if (myScore > oppScore) wins++;
      totalTeamGoals += myScore;
      totalConceded += oppScore;

      final vote = m.votes[playerId];
      if (vote != null && vote > 0) {
        allVotes.add(vote);
        if (isLoss) votesInLoss.add(vote);
      }
    }

    final votedGames = allVotes.length;
    final avgVote =
        votedGames > 0 ? allVotes.reduce((a, b) => a + b) / votedGames : 6.0;

    // ── VEL: frequenza recente + gol/partita + partite ad alto scoring ───────
    //
    // Componente 1 (30%): frequenza recente
    //   Conta le partite del giocatore negli ultimi 60 giorni e le confronta
    //   con la media mensile del gruppo intero (partiteGruppo / mesiAttivi).
    //   Ratio ≥ 1.0 significa che il giocatore è sopra la media → vel alta.
    final now = DateTime.now();
    final cutoff60 = now.subtract(const Duration(days: 60));
    final recentGames = matches.where((m) => m.date.isAfter(cutoff60)).length;

    // Media mensile del gruppo: tutte le partite nel sistema / mesi di attività
    final allMatchesSorted = HiveBoxes.matchesBox.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    double groupMonthlyAvg = 1.0;
    if (allMatchesSorted.length >= 2) {
      final firstDate = allMatchesSorted.first.date;
      final lastDate = allMatchesSorted.last.date;
      final monthsActive = ((lastDate.difference(firstDate).inDays) / 30.0)
          .clamp(1.0, double.infinity);
      groupMonthlyAvg = allMatchesSorted.length / monthsActive;
    }
    // Il giocatore ha giocato X partite in 2 mesi → confronto con 2× mensile
    final recentExpected = groupMonthlyAvg * 2;
    final velRecent =
        _scale(recentGames.toDouble(), 0.0, recentExpected, 40, 99);

    // Componente 2 (40%): gol/partita — 2 gol a partita → 99
    final goalsPerGame = totalGoals / totalGames;
    final velGoals = _scale(goalsPerGame, 0.0, 2.0, 40, 99);

    // Componente 3 (25%): % partite in cui il giocatore segna
    final scoringRate = gamesWithGoal / totalGames;
    final velScoring = _scale(scoringRate, 0.0, 0.8, 40, 99);

    final vel = (velRecent * 0.35 + velGoals * 0.40 + velScoring * 0.25)
        .round()
        .clamp(40, 99);

    // ── TIR: gol/partita + bonus MVP e BestGoal ───────────────────────────
    final tirBase = _scale(goalsPerGame, 0.0, 2.0, 40, 92);
    final tirBonus = mvpCount.clamp(0, 4) + (bestGoalCount * 2).clamp(0, 6);
    final tir = (tirBase + tirBonus).round().clamp(40, 99);

    // ── Dati di squadra condivisi da PAS, DIF e FIS ──────────────────────
    final presenceRate = (totalGames / totalRegistered).clamp(0.0, 1.0);
    final winRate = wins / totalGames;
    final hustleRate = hustleCount / totalGames;
    final mvpRate = mvpCount / totalGames;
    final voteScore = _scale(avgVote, 5.0, 8.0, 40, 99);

    // ── PAS: gol compagni + vittorie + presenze + voto medio ─────────────
    // Gol dei compagni/partita come proxy degli assist: 3→40, 8→99
    final teammateGoalsPerGame =
        (totalTeamGoals - totalGoals).clamp(0, totalTeamGoals) / totalGames;
    final pasTeammates = _scale(teammateGoalsPerGame, 3.0, 8.0, 40, 99);
    final pasWins = _scale(winRate, 0.2, 0.7, 40, 99);
    final pasPresence = _scale(presenceRate, 0.0, 0.75, 40, 99);

    final pas = (pasTeammates * 0.30 +
            pasWins * 0.30 +
            pasPresence * 0.20 +
            voteScore * 0.20)
        .round()
        .clamp(40, 99);

    // ── DRI: gol/partita + MVP + voto medio ──────────────────────────────
    final driGoals = _scale(goalsPerGame, 0.0, 2.0, 40, 99);
    final driMvp = _scale(mvpRate, 0.0, 0.25, 40, 99);

    final dri = (driGoals * 0.40 + driMvp * 0.35 + voteScore * 0.25)
        .round()
        .clamp(40, 99);

    // ── DIF: gol subiti vs gruppo + Combattivo + ruolo + voto sconfitte ──
    // Media gol subiti per squadra nel gruppo (tutte le partite registrate):
    // confrontarsi con il gruppo rende la stat indipendente da quanto si
    // segna in media. Gruppo senza gol subiti → rapporto neutro 1.0.
    int groupGoals = 0;
    for (final m in allMatchesSorted) {
      groupGoals += m.scoreA + m.scoreB;
    }
    final groupConcededPerTeam = groupGoals / (2 * allMatchesSorted.length);
    final concededPerGame = totalConceded / totalGames;
    final concededRatio =
        groupConcededPerTeam > 0 ? concededPerGame / groupConcededPerTeam : 1.0;
    final difConceded = _scale(concededRatio, 0.7, 1.3, 99, 40);
    final difCombattivo = _scale(hustleRate, 0.0, 0.2, 45, 99);
    final difRole = difRoleScore(player?.role ?? '').toDouble();

    final avgVoteLoss = votesInLoss.isNotEmpty
        ? votesInLoss.reduce((a, b) => a + b) / votesInLoss.length
        : avgVote;
    final difVoto = _scale(avgVoteLoss, 4.0, 8.0, 40, 99);

    final dif = (difConceded * 0.35 +
            difCombattivo * 0.25 +
            difRole * 0.20 +
            difVoto * 0.20)
        .round()
        .clamp(40, 99);

    // ── FIS: presenze + Combattivo + imbattibilità + ruolo + voto medio ───
    //
    // Pensato per il calcetto: le partite finiscono quasi sempre con molti
    // gol, quindi niente componenti legate al "basso punteggio"; e soglie
    // raggiungibili da un titolare (non 10 vittorie di fila).

    // Componente 1 (30%): presenze — un titolare (≥75%) prende il massimo
    final fisPresence = _scale(presenceRate, 0.0, 0.75, 40, 99);

    // Componente 2 (25%): premi Combattivo — 1 ogni 5 partite → 99
    final fisHustle = _scale(hustleRate, 0.0, 0.2, 45, 99);

    // Componente 3 (20%): miglior serie senza sconfitte (V o P)
    int bestUnbeaten = 0;
    int currentUnbeaten = 0;
    for (final m in matches) {
      final inTeamA = m.teamA.contains(playerId);
      final myScore = inTeamA ? m.scoreA : m.scoreB;
      final oppScore = inTeamA ? m.scoreB : m.scoreA;
      if (myScore >= oppScore) {
        currentUnbeaten++;
        if (currentUnbeaten > bestUnbeaten) bestUnbeaten = currentUnbeaten;
      } else {
        currentUnbeaten = 0;
      }
    }
    final fisUnbeaten = _scale(bestUnbeaten.toDouble(), 0.0, 6.0, 40, 99);

    // Componente 4 (15%): ruolo
    final fisRole = fisRoleScore(player?.role ?? '').toDouble();

    // Componente 5 (10%): voto medio come misura dell'impegno
    final fisVote = voteScore;

    final fisRaw = fisPresence * 0.30 +
        fisHustle * 0.25 +
        fisUnbeaten * 0.20 +
        fisRole * 0.15 +
        fisVote * 0.10;
    final fis = fisRaw.round().clamp(40, 99);

    return ComputedFifaStats(
      vel: vel,
      tir: tir,
      pas: pas,
      dri: dri,
      dif: dif,
      fis: fis,
    );
  }

  // ── Scala lineare [inMin, inMax] → [outMin, outMax] ───────────────────
  static double _scale(
    double value,
    double inMin,
    double inMax,
    double outMin,
    double outMax,
  ) {
    if (inMax == inMin) return outMin;
    final t = ((value - inMin) / (inMax - inMin)).clamp(0.0, 1.0);
    return outMin + t * (outMax - outMin);
  }

  // ── Ruolo ─────────────────────────────────────────────────────────
  //   L'app salva i ruoli come lettera singola (P/D/C/A); i nomi lunghi
  //   (DIF, POR, CEN, …) restano riconosciuti per i dati più vecchi.
  //   Ritorna 'D', 'P', 'C' oppure 'A' (attaccante o sconosciuto).
  static String _roleCategory(String role) {
    final r = role.trim().toUpperCase();
    if (const {'D', 'P', 'C', 'A'}.contains(r)) return r;
    if (r.contains('DIF') ||
        r.contains('TER') ||
        r.contains('LIB') ||
        r.contains('STO')) {
      return 'D';
    }
    if (r.contains('POR')) return 'P';
    if (r.contains('CEN') ||
        r.contains('MED') ||
        r.contains('INT') ||
        r.contains('TRE')) {
      return 'C';
    }
    return 'A';
  }

  /// Punteggio ruolo per FIS (scala 40–99): D 99 · P 90 · C 80 · A 65.
  static int fisRoleScore(String role) =>
      const {'D': 99, 'P': 90, 'C': 80, 'A': 65}[_roleCategory(role)]!;

  /// Punteggio ruolo per DIF (scala 40–99): D 99 · P 95 · C 75 · A 55.
  static int difRoleScore(String role) =>
      const {'D': 99, 'P': 95, 'C': 75, 'A': 55}[_roleCategory(role)]!;
}
