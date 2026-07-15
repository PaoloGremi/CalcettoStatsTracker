import '../data/hive_boxes.dart';

/// Statistiche FIFA calcolate automaticamente dai dati reali delle partite.
class ComputedFifaStats {
  final int
      vel; // Velocità  → frequenza recente (30%) + gol/partita (40%) + partite ad alto scoring (30%)
  final int tir; // Tiro      → gol/partita + bonus premi MVP/BestGoal
  final int
      pas; // Passaggio → gol squadra (30%) + gol subiti inverso (25%) + presenze (20%) + gol compagni (25%)
  final int
      dri; // Dribbling → gol fatti (30%) + gol subiti squadra (25%) + MVP (25%) + alto scoring (20%)
  final int dif; // Difesa    → premio Combattivo + voto medio nelle sconfitte
  final int
      fis; // Fisico    → basso scoring (25%) + presenze (25%) + striscia vittorie (20%) + Hustle (20%) + ruolo (10%)

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
  /// │ VEL │ Media pesata di 3 componenti:                                  │
  /// │     │ 30% Frequenza recente: partite ultimi 60gg / media mese gruppo │
  /// │     │ 40% Gol/partita: 0→40, ≥1 gol/p→99                            │
  /// │     │ 30% Partite ad alto scoring (tot. gol ≥5): 0%→40, 100%→99     │
  /// ├─────┼────────────────────────────────────────────────────────────────┤
  /// │ TIR │ Gol/partita (base 40–95) + bonus premi:                        │
  /// │     │ +2 per MVP (max +4) · +2 per BestGoal (max +4) · cap: 99      │
  /// ├─────┼────────────────────────────────────────────────────────────────┤
  /// │ PAS │ Media pesata di 4 componenti:                                  │
  /// │     │ 30% Gol squadra/partita: 0→40, ≥3/p→99                        │
  /// │     │ 25% Gol subiti/partita (inverso): 0→99, ≥3/p→40               │
  /// │     │ 20% Presenze (partiteGiocate / totale sistema): 0%→40, 100%→99 │
  /// │     │ 25% Gol compagni/partita (tot.squadra − propri): 0→40, ≥2/p→99 │
  /// ├─────┼────────────────────────────────────────────────────────────────┤
  /// │ DRI │ Media pesata di 4 componenti:                                  │
  /// │     │ 30% Gol segnati/partita: 0→40, ≥1/p→99                        │
  /// │     │ 25% Gol subiti squadra/partita: 0→40, ≥3/p→99                 │
  /// │     │ 25% Premi MVP: +3 per MVP scalato 40–99, cap 99               │
  /// │     │ 20% % partite alto scoring (tot. gol ≥5): 0%→40, 100%→99      │
  /// ├─────┼────────────────────────────────────────────────────────────────┤
  /// │ DIF │ 50% premio Combattivo (hustleCount/partite scalato 40–99)      │
  /// │     │ + 50% voto medio nelle sconfitte (4→40, 10→99).               │
  /// │     │ Fallback su voto medio globale se nessuna sconfitta votata.    │
  /// ├─────┼────────────────────────────────────────────────────────────────┤
  /// │ FIS │ Media pesata di 5 componenti:                                  │
  /// │     │ 25% Partite basso scoring (tot. gol ≤2): 0%→40, 100%→99       │
  /// │     │ 25% Presenze (partiteGiocate / totale sistema): 0%→40, 100%→99 │
  /// │     │ 20% Miglior striscia vittorie consecutive: 0→40, ≥10→99        │
  /// │     │ 20% Premi Hustle (rate/partita): 0→40, 1 ogni 3 partite→99     │
  /// │     │ 10% Bonus ruolo: DIF/TER+6, POR+4, CEN/MED+3, ATT/ALA+0       │
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

      totalGoals += m.goals[playerId] ?? 0;

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

    // Componente 2 (40%): gol/partita
    final goalsPerGame = totalGoals / totalGames;
    final velGoals = _scale(goalsPerGame, 0.0, 1.0, 40, 99);

    // Componente 3 (30%): % partite ad alto scoring (totale gol ≥ 5)
    int highScoringGames = 0;
    for (final m in matches) {
      if ((m.scoreA + m.scoreB) >= 5) highScoringGames++;
    }
    final highScoringRate = highScoringGames / totalGames;
    final velHighScore = _scale(highScoringRate, 0.0, 1.0, 40, 99);

    final vel = (velRecent * 0.3 + velGoals * 0.4 + velHighScore * 0.3)
        .toInt()
        .clamp(40, 99);

    // ── TIR: gol/partita + bonus MVP e BestGoal ───────────────────────────
    final tirBase = _scale(goalsPerGame, 0.0, 1.0, 40, 95);
    final tirBonus =
        (mvpCount * 2).clamp(0, 4) + (bestGoalCount * 2).clamp(0, 4);
    final tir = (tirBase + tirBonus).toInt().clamp(40, 99);

    // ── PAS: gol squadra + gol subiti inverso + presenze + gol compagni ──

    // presenceRate usato sia da PAS che da FIS — dichiarato qui
    final presenceRate = (totalGames / totalRegistered).clamp(0.0, 1.0);

    // Raccolta dati di squadra nelle partite del giocatore
    int totalTeamGoals = 0; // gol segnati dalla squadra del giocatore
    // totalConceded già calcolato nel blocco DRI — lo ricalcoliamo qui
    // per chiarezza (stesso loop, nessun impatto sulle performance)
    int pasTotalConceded = 0;
    for (final m in matches) {
      final inTeamA = m.teamA.contains(playerId);
      totalTeamGoals += inTeamA ? m.scoreA : m.scoreB;
      pasTotalConceded += inTeamA ? m.scoreB : m.scoreA;
    }

    // Componente 1 (30%): gol segnati dalla squadra/partita
    //   0 gol/p → 40, ≥3/p → 99
    final teamGoalsPerGame = totalTeamGoals / totalGames;
    final pasTeamGoals = _scale(teamGoalsPerGame, 0.0, 3.0, 40, 99);

    // Componente 2 (25%): gol subiti/partita — scala inversa
    //   0 subiti/p → 99, ≥3/p → 40
    final pasConcededPerGame = pasTotalConceded / totalGames;
    final pasConceded = _scale(pasConcededPerGame, 0.0, 3.0, 99, 40);

    // Componente 3 (20%): presenze
    final pasPresence = _scale(presenceRate, 0.0, 1.0, 40, 99);

    // Componente 4 (25%): gol dei compagni/partita
    //   (gol totali squadra − gol propri) / partite → proxy assist
    //   0 → 40, ≥2/p → 99
    final teammateGoalsPerGame =
        (totalTeamGoals - totalGoals).clamp(0, totalTeamGoals) / totalGames;
    final pasTeammates = _scale(teammateGoalsPerGame, 0.0, 2.0, 40, 99);

    final pas = (pasTeamGoals * 0.30 +
            pasConceded * 0.25 +
            pasPresence * 0.20 +
            pasTeammates * 0.25)
        .toInt()
        .clamp(40, 99);

    // ── DRI: gol fatti + gol subiti squadra + MVP + alto scoring ─────────
    //
    // Componente 1 (30%): gol segnati/partita
    final driGoals = _scale(goalsPerGame, 0.0, 1.0, 40, 99);

    // Componente 2 (25%): gol subiti dalla squadra/partita
    //   Chi gioca partite difensivamente aperte tende ad essere un dribblatore
    //   che privilegia l'attacco alla copertura. 0→40, ≥3/p→99.
    int totalConceded = 0;
    for (final m in matches) {
      final inTeamA = m.teamA.contains(playerId);
      totalConceded += inTeamA ? m.scoreB : m.scoreA;
    }
    final concededPerGame = totalConceded / totalGames;
    final driConceded = _scale(concededPerGame, 0.0, 3.0, 40, 99);

    // Componente 3 (25%): premi MVP
    //   +3 per ogni MVP, scalato su 40–99 con cap a 99.
    //   Soglia: 1 MVP ogni 3 partite (mvpRate 0.33) → massimo.
    final mvpRate = mvpCount / totalGames;
    final driMvp = _scale(mvpRate, 0.0, 0.33, 40, 99);

    // Componente 4 (20%): % partite ad alto scoring (tot. gol ≥ 5)
    //   Riutilizza highScoringRate già calcolato per VEL.
    final driHighScore = _scale(highScoringRate, 0.0, 1.0, 40, 99);

    final dri = (driGoals * 0.30 +
            driConceded * 0.25 +
            driMvp * 0.25 +
            driHighScore * 0.20)
        .toInt()
        .clamp(40, 99);

    // ── DIF: 50% Combattivo + 50% voto nelle sconfitte ────────────────────
    // hustleRate: 0 premi → 40, 1 premio ogni 3 partite (0.33) → 99
    final hustleRate = hustleCount / totalGames;
    final difCombattivo = _scale(hustleRate, 0.0, 0.33, 40, 99);

    final avgVoteLoss = votesInLoss.isNotEmpty
        ? votesInLoss.reduce((a, b) => a + b) / votesInLoss.length
        : avgVote;
    final difVoto = _scale(avgVoteLoss, 4.0, 10.0, 40, 99);

    final dif = ((difCombattivo * 0.5) + (difVoto * 0.5)).toInt().clamp(40, 99);

    // ── FIS: basso scoring + presenze + striscia vittorie + Hustle + ruolo ──

    // Componente 1 (25%): % partite a basso scoring (totale gol ≤ 2)
    int lowScoringGames = 0;
    for (final m in matches) {
      if ((m.scoreA + m.scoreB) <= 2) lowScoringGames++;
    }
    final lowScoringRate = lowScoringGames / totalGames;
    final fisLowScore = _scale(lowScoringRate, 0.0, 1.0, 40, 99);

    // Componente 2 (25%): presenze (partite giocate / totale nel sistema)
    // presenceRate già dichiarato prima del blocco PAS
    final fisPresence = _scale(presenceRate, 0.0, 1.0, 40, 99);

    // Componente 3 (20%): miglior striscia di vittorie consecutive
    //   0 vittorie consecutive → 40, ≥10 → 99
    int bestWinStreak = 0;
    int currentWinStreak = 0;
    for (final m in matches) {
      final inTeamA = m.teamA.contains(playerId);
      final myScore = inTeamA ? m.scoreA : m.scoreB;
      final oppScore = inTeamA ? m.scoreB : m.scoreA;
      if (myScore > oppScore) {
        currentWinStreak++;
        if (currentWinStreak > bestWinStreak) bestWinStreak = currentWinStreak;
      } else {
        currentWinStreak = 0;
      }
    }
    final fisStreak = _scale(bestWinStreak.toDouble(), 0.0, 10.0, 40, 99);

    // Componente 4 (20%): premi Hustle
    //   0 premi → 40, 1 premio ogni 3 partite (rate 0.33) → 99
    final fisHustle = _scale(hustleRate, 0.0, 0.33, 40, 99);

    // Componente 5 (10%): bonus ruolo (valore fisso normalizzato su 40–99)
    //   DIF/TER → +6 (fisico massimo), POR → +4, CEN/MED → +3, ATT/ALA → 0
    final roleBonus = _defRoleBonus(player?.role ?? '');
    // Il bonus è un offset diretto sul risultato finale (non sul raw 0–1)
    // Lo trattiamo come una componente fissa: bonus 0→40, bonus 6→99
    final fisRole = _scale(roleBonus.toDouble(), 0.0, 6.0, 40, 99);

    final fisRaw = fisLowScore * 0.25 +
        fisPresence * 0.25 +
        fisStreak * 0.20 +
        fisHustle * 0.20 +
        fisRole * 0.10;
    final fis = fisRaw.toInt().clamp(40, 99);

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

  // ── Bonus ruolo difensivo per FIS ─────────────────────────────────────
  //   DIF / TER(minatore) → 6  (massimo fisico)
  //   POR(tiere)          → 4
  //   CEN(trocampista) / MED(iano) → 3
  //   ATT(accante) / ALA  → 0  (nessun bonus)
  static int _defRoleBonus(String role) {
    final r = role.toUpperCase();
    if (r.contains('DIF') ||
        r.contains('TER') ||
        r.contains('LIB') ||
        r.contains('STO')) {
      return 6;
    }
    if (r.contains('POR')) return 4;
    if (r.contains('CEN') ||
        r.contains('MED') ||
        r.contains('INT') ||
        r.contains('TRE')) {
      return 3;
    }
    return 0;
  }
}
