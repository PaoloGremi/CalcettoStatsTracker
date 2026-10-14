import 'package:calcetto_tracker/models/match_model.dart';

enum MatchOutcome {
  win('V'),
  draw('P'),
  loss('S');

  const MatchOutcome(this.label);
  final String label;
}

typedef VotePoint = ({int matchIndex, double vote});
typedef RelativeVote = ({DateTime date, double delta});
typedef RecentResult = ({MatchOutcome outcome, double? vote, DateTime date});

/// Statistiche aggregate di un giocatore, calcolate in Dart puro.
/// Non lancia mai eccezioni: liste vuote producono zeri / null.
class PlayerStatsSummary {
  static const int movingWindow = 5;
  static const int recentCount = 10;

  final String playerId;
  final List<MatchModel> matches;
  final int totalGames,
      votedGames,
      totalGoals,
      wins,
      draws,
      losses,
      participationPct,
      bestUnbeaten,
      gamesWithGoal;
  final double avgVote, bestVote, worstVote, avgGoals;
  final double? modeVote;
  final String currentStreak;
  final List<VotePoint> votePoints;
  final List<int> goalsPerMatch;
  final List<int> cumulativeGoals;
  final Map<String, int> matchesByMonth;
  final Map<String, int> goalsByMonth;
  final Map<String, double> avgVoteByMonth;
  final Map<String, int> voteDistribution;
  final List<VotePoint> movingAvgVotes;
  final List<({int matchIndex, double pct})> rollingWinRate;
  final List<RecentResult> recentResults;
  final Map<MatchOutcome, List<double>> votesByOutcome;
  final List<RelativeVote> relativeVotes;
  final double avgRelativeVote;
  final int aboveAvgPct;

  const PlayerStatsSummary._({
    required this.playerId,
    required this.matches,
    required this.totalGames,
    required this.votedGames,
    required this.totalGoals,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.participationPct,
    required this.bestUnbeaten,
    required this.gamesWithGoal,
    required this.avgVote,
    required this.bestVote,
    required this.worstVote,
    required this.avgGoals,
    required this.modeVote,
    required this.currentStreak,
    required this.votePoints,
    required this.goalsPerMatch,
    required this.cumulativeGoals,
    required this.matchesByMonth,
    required this.goalsByMonth,
    required this.avgVoteByMonth,
    required this.voteDistribution,
    required this.movingAvgVotes,
    required this.rollingWinRate,
    required this.recentResults,
    required this.votesByOutcome,
    required this.relativeVotes,
    required this.avgRelativeVote,
    required this.aboveAvgPct,
  });

  /// Risultato della partita dal punto di vista del giocatore.
  MatchOutcome outcomeOf(MatchModel m) {
    final f = goalsForOf(m), a = goalsAgainstOf(m);
    if (f > a) return MatchOutcome.win;
    if (f == a) return MatchOutcome.draw;
    return MatchOutcome.loss;
  }

  int goalsForOf(MatchModel m) =>
      m.teamA.contains(playerId) ? m.scoreA : m.scoreB;

  int goalsAgainstOf(MatchModel m) =>
      m.teamA.contains(playerId) ? m.scoreB : m.scoreA;

  static String _monthKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  static PlayerStatsSummary compute({
    required String playerId,
    required List<MatchModel> allMatches,
  }) {
    final matches = allMatches
        .where((m) => m.teamA.contains(playerId) || m.teamB.contains(playerId))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Istanza "vuota" usata solo per i helper outcomeOf/goalsForOf.
    PlayerStatsSummary helper() => PlayerStatsSummary._(
          playerId: playerId,
          matches: matches,
          totalGames: 0,
          votedGames: 0,
          totalGoals: 0,
          wins: 0,
          draws: 0,
          losses: 0,
          participationPct: 0,
          bestUnbeaten: 0,
          gamesWithGoal: 0,
          avgVote: 0,
          bestVote: 0,
          worstVote: 0,
          avgGoals: 0,
          modeVote: null,
          currentStreak: '—',
          votePoints: const [],
          goalsPerMatch: const [],
          cumulativeGoals: const [],
          matchesByMonth: const {},
          goalsByMonth: const {},
          avgVoteByMonth: const {},
          voteDistribution: const {},
          movingAvgVotes: const [],
          rollingWinRate: const [],
          recentResults: const [],
          votesByOutcome: const {},
          relativeVotes: const [],
          avgRelativeVote: 0,
          aboveAvgPct: 0,
        );
    final h = helper();

    final votePoints = <VotePoint>[];
    final goalsPerMatch = <int>[];
    final cumulativeGoals = <int>[];
    final outcomes = <MatchOutcome>[];
    final matchesByMonth = <String, int>{};
    final goalsByMonth = <String, int>{};
    final votesByMonth = <String, List<double>>{};
    final votesByOutcome = <MatchOutcome, List<double>>{
      for (final o in MatchOutcome.values) o: <double>[],
    };
    var wins = 0, draws = 0, losses = 0, cum = 0;

    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final vote = m.votes[playerId];
      final goals = m.goals[playerId] ?? 0;
      final outcome = h.outcomeOf(m);
      final key = _monthKey(m.date);
      outcomes.add(outcome);
      switch (outcome) {
        case MatchOutcome.win:
          wins++;
        case MatchOutcome.draw:
          draws++;
        case MatchOutcome.loss:
          losses++;
      }
      goalsPerMatch.add(goals);
      cum += goals;
      cumulativeGoals.add(cum);
      matchesByMonth[key] = (matchesByMonth[key] ?? 0) + 1;
      goalsByMonth[key] = (goalsByMonth[key] ?? 0) + goals;
      if (vote != null) {
        votePoints.add((matchIndex: i, vote: vote));
        votesByMonth.putIfAbsent(key, () => []).add(vote);
        votesByOutcome[outcome]!.add(vote);
      }
    }

    final totalGames = matches.length;
    final votedGames = votePoints.length;
    final votes = votePoints.map((p) => p.vote).toList();
    final avgVote =
        votedGames > 0 ? votes.reduce((a, b) => a + b) / votedGames : 0.0;
    final bestVote =
        votedGames > 0 ? votes.reduce((a, b) => a > b ? a : b) : 0.0;
    final worstVote =
        votedGames > 0 ? votes.reduce((a, b) => a < b ? a : b) : 0.0;
    final totalGoals = cum;
    final avgGoals = totalGames > 0 ? totalGoals / totalGames : 0.0;
    final participationPct = allMatches.isNotEmpty
        ? (totalGames / allMatches.length * 100).round()
        : 0;
    final gamesWithGoal = goalsPerMatch.where((g) => g > 0).length;

    // Striscia corrente
    var currentStreak = '—';
    if (outcomes.isNotEmpty) {
      final last = outcomes.last;
      var count = 0;
      for (int i = outcomes.length - 1; i >= 0; i--) {
        if (outcomes[i] != last) break;
        count++;
      }
      currentStreak = '$count${last.label}';
    }

    // Miglior serie senza sconfitte
    var bestUnbeaten = 0, curUnbeaten = 0;
    for (final o in outcomes) {
      if (o != MatchOutcome.loss) {
        curUnbeaten++;
        if (curUnbeaten > bestUnbeaten) bestUnbeaten = curUnbeaten;
      } else {
        curUnbeaten = 0;
      }
    }

    // Moda dei voti (a parità vince l'ultimo inserito, come nella schermata)
    final freq = <double, int>{};
    for (final v in votes) {
      freq[v] = (freq[v] ?? 0) + 1;
    }
    double? modeVote;
    if (freq.isNotEmpty) {
      modeVote = freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    // Distribuzione voti
    final voteDistribution = <String, int>{
      '1-2': 0,
      '3-4': 0,
      '5-6': 0,
      '7-8': 0,
      '9-10': 0,
    };
    for (final v in votes) {
      final k = v <= 2
          ? '1-2'
          : v <= 4
              ? '3-4'
              : v <= 6
                  ? '5-6'
                  : v <= 8
                      ? '7-8'
                      : '9-10';
      voteDistribution[k] = voteDistribution[k]! + 1;
    }

    final avgVoteByMonth = <String, double>{
      for (final e in votesByMonth.entries)
        if (e.value.isNotEmpty)
          e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };

    // Media mobile voti
    final movingAvgVotes = <VotePoint>[];
    for (int i = movingWindow - 1; i < votePoints.length; i++) {
      final window = votePoints.sublist(i - movingWindow + 1, i + 1);
      final avg =
          window.map((p) => p.vote).reduce((a, b) => a + b) / movingWindow;
      movingAvgVotes.add((matchIndex: votePoints[i].matchIndex, vote: avg));
    }

    // Win-rate rolling
    final rollingWinRate = <({int matchIndex, double pct})>[];
    for (int i = movingWindow - 1; i < outcomes.length; i++) {
      final w = outcomes
          .sublist(i - movingWindow + 1, i + 1)
          .where((o) => o == MatchOutcome.win)
          .length;
      rollingWinRate.add((matchIndex: i, pct: w / movingWindow * 100));
    }

    // Form recente
    final start =
        matches.length > recentCount ? matches.length - recentCount : 0;
    final recentResults = <RecentResult>[
      for (int i = start; i < matches.length; i++)
        (
          outcome: outcomes[i],
          vote: matches[i].votes[playerId],
          date: matches[i].date,
        ),
    ];

    // Voto relativo: voto del giocatore meno la media degli altri votati.
    final relativeVotes = <RelativeVote>[];
    for (final m in matches) {
      final mine = m.votes[playerId];
      if (mine == null) continue;
      final others = [
        for (final e in m.votes.entries)
          if (e.key != playerId) e.value,
      ];
      if (others.isEmpty) continue;
      final mean = others.reduce((a, b) => a + b) / others.length;
      relativeVotes.add((date: m.date, delta: mine - mean));
    }
    final avgRelativeVote = relativeVotes.isNotEmpty
        ? relativeVotes.map((r) => r.delta).reduce((a, b) => a + b) /
            relativeVotes.length
        : 0.0;
    final aboveAvgPct = relativeVotes.isNotEmpty
        ? (relativeVotes.where((r) => r.delta > 0).length /
                relativeVotes.length *
                100)
            .round()
        : 0;

    return PlayerStatsSummary._(
      playerId: playerId,
      matches: matches,
      totalGames: totalGames,
      votedGames: votedGames,
      totalGoals: totalGoals,
      wins: wins,
      draws: draws,
      losses: losses,
      participationPct: participationPct,
      bestUnbeaten: bestUnbeaten,
      gamesWithGoal: gamesWithGoal,
      avgVote: avgVote,
      bestVote: bestVote,
      worstVote: worstVote,
      avgGoals: avgGoals,
      modeVote: modeVote,
      currentStreak: currentStreak,
      votePoints: votePoints,
      goalsPerMatch: goalsPerMatch,
      cumulativeGoals: cumulativeGoals,
      matchesByMonth: matchesByMonth,
      goalsByMonth: goalsByMonth,
      avgVoteByMonth: avgVoteByMonth,
      voteDistribution: voteDistribution,
      movingAvgVotes: movingAvgVotes,
      rollingWinRate: rollingWinRate,
      recentResults: recentResults,
      votesByOutcome: votesByOutcome,
      relativeVotes: relativeVotes,
      avgRelativeVote: avgRelativeVote,
      aboveAvgPct: aboveAvgPct,
    );
  }
}
