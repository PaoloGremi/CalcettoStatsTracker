import 'package:calcetto_tracker/models/match_model.dart';
import 'package:calcetto_tracker/services/player_stats_summary.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel m(String id, DateTime date,
        {List<String> a = const ['p1', 'x'],
        List<String> b = const ['y', 'z'],
        int sa = 0,
        int sb = 0,
        Map<String, double>? votes,
        Map<String, int>? goals,
        String mvp = ''}) =>
    MatchModel(
        id: id,
        date: date,
        teamA: a,
        teamB: b,
        scoreA: sa,
        scoreB: sb,
        votes: votes,
        goals: goals,
        fieldLocation: 'f1',
        mvp: mvp,
        hustlePlayer: '');

/// Partita con p1 in teamA e risultato scelto: 'V', 'P' o 'S'.
MatchModel res(String id, DateTime date, String r,
        {Map<String, double>? votes, Map<String, int>? goals}) =>
    m(id, date,
        sa: r == 'V' ? 2 : (r == 'P' ? 1 : 0),
        sb: r == 'S' ? 2 : (r == 'P' ? 1 : 0),
        votes: votes,
        goals: goals);

void main() {
  group('existing stats', () {
    test('empty match list yields zeros and no crash', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: []);
      expect(s.totalGames, 0);
      expect(s.avgVote, 0.0);
      expect(s.modeVote, isNull);
      expect(s.currentStreak, '—');
      expect(s.participationPct, 0);
    });

    test('ignores matches the player did not play and sorts by date', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        m('3', DateTime(2026, 3, 1)),
        m('2', DateTime(2026, 2, 1), a: ['q'], b: ['r']),
        m('1', DateTime(2026, 1, 1)),
      ]);
      expect(s.totalGames, 2);
      expect(s.matches.first.date, DateTime(2026, 1, 1));
      expect(s.participationPct, 67);
    });

    test('counts W/D/L from both sides', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        m('1', DateTime(2026, 1, 1), sa: 3, sb: 1),
        m('2', DateTime(2026, 1, 2),
            a: ['y', 'z'], b: ['p1', 'x'], sa: 2, sb: 2),
        m('3', DateTime(2026, 1, 3),
            a: ['y', 'z'], b: ['p1', 'x'], sa: 4, sb: 0),
      ]);
      expect(s.wins, 1);
      expect(s.draws, 1);
      expect(s.losses, 1);
    });

    test('current streak and best unbeaten', () {
      final seq = ['V', 'V', 'S', 'P', 'V', 'V', 'V'];
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        for (var i = 0; i < seq.length; i++)
          res('$i', DateTime(2026, 1, i + 1), seq[i]),
      ]);
      expect(s.currentStreak, '3V');
      expect(s.bestUnbeaten, 4);
    });

    test('vote aggregates', () {
      final votes = [6.0, 8.0, 8.0, null, 5.0];
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        for (var i = 0; i < votes.length; i++)
          m('$i', DateTime(2026, 1, i + 1),
              votes: votes[i] == null ? null : {'p1': votes[i]!}),
      ]);
      expect(s.votedGames, 4);
      expect(s.avgVote, 6.75);
      expect(s.bestVote, 8);
      expect(s.worstVote, 5);
      expect(s.modeVote, 8);
      expect(s.votePoints.map((p) => p.matchIndex), [0, 1, 2, 4]);
      expect(s.voteDistribution['7-8'], 2);
      expect(s.voteDistribution['5-6'], 2);
    });

    test('matches with no votes at all do not crash', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        for (var i = 0; i < 3; i++) m('$i', DateTime(2026, 1, i + 1)),
      ]);
      expect(s.votedGames, 0);
      expect(s.bestVote, 0.0);
      expect(s.movingAvgVotes, isEmpty);
    });

    test('goals and monthly maps', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        m('1', DateTime(2026, 1, 5), goals: {'p1': 2}),
        m('2', DateTime(2026, 1, 12), goals: {'p1': 0}),
        m('3', DateTime(2026, 2, 3), goals: {'p1': 1}),
      ]);
      expect(s.totalGoals, 3);
      expect(s.gamesWithGoal, 2);
      expect(s.cumulativeGoals, [2, 2, 3]);
      expect(s.goalsByMonth, {'2026-01': 2, '2026-02': 1});
      expect(s.matchesByMonth, {'2026-01': 2, '2026-02': 1});
    });

    test('rolling windows need 5 entries', () {
      final seq = ['V', 'V', 'S', 'V', 'S', 'V'];
      final votes = [6.0, 7.0, 8.0, 9.0, 10.0, 10.0];
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        for (var i = 0; i < seq.length; i++)
          res('$i', DateTime(2026, 1, i + 1), seq[i], votes: {'p1': votes[i]}),
      ]);
      expect(s.rollingWinRate.length, 2);
      expect(s.rollingWinRate.first.pct, 60);
      expect(s.movingAvgVotes.length, 2);
    });

    test('recent results keep the last 10', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        for (var i = 0; i < 12; i++) res('$i', DateTime(2026, 1, i + 1), 'V'),
      ]);
      expect(s.recentResults.length, 10);
      expect(s.recentResults.first.date, s.matches[2].date);
    });
  });

  group('relative vote', () {
    test(
        'delta is vote minus the mean of every other voted player in the match',
        () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        m('1', DateTime(2026, 1, 1), votes: {'p1': 8, 'x': 6, 'y': 7}),
      ]);
      expect(s.relativeVotes.single.delta, 1.5);
      expect(s.relativeVotes.single.date, DateTime(2026, 1, 1));
    });

    test('skips matches where p1 has no vote or nobody else voted', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        m('1', DateTime(2026, 1, 1), votes: {'p1': 8}),
        m('2', DateTime(2026, 1, 2), votes: {'x': 6}),
      ]);
      expect(s.relativeVotes, isEmpty);
      expect(s.avgRelativeVote, 0.0);
      expect(s.aboveAvgPct, 0);
    });

    test('average and above-average percentage', () {
      // deltas: +1, -0.5, +2
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        m('1', DateTime(2026, 1, 1), votes: {'p1': 7, 'x': 6}),
        m('2', DateTime(2026, 1, 2), votes: {'p1': 5.5, 'x': 6}),
        m('3', DateTime(2026, 1, 3), votes: {'p1': 8, 'x': 6}),
      ]);
      expect(s.avgRelativeVote, closeTo(0.833, 0.001));
      expect(s.aboveAvgPct, 67);
    });
  });

  group('goals extras', () {
    test('team goal share uses the team score as denominator', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        m('1', DateTime(2026, 1, 1), sa: 3, sb: 0, goals: {'p1': 1}),
        m('2', DateTime(2026, 1, 2),
            a: ['y', 'z'], b: ['p1', 'x'], sa: 0, sb: 2, goals: {'p1': 2}),
      ]);
      expect(s.teamGoals, 5);
      expect(s.teamGoalShare, closeTo(0.6, 1e-9));
    });

    test('share is null when the team never scores', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        m('1', DateTime(2026, 1, 1)),
        m('2', DateTime(2026, 1, 2)),
      ]);
      expect(s.teamGoals, 0);
      expect(s.teamGoalShare, isNull);
    });

    test('braces, hat tricks and max goals', () {
      final gs = [2, 3, 0, 4, 2];
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        for (var i = 0; i < gs.length; i++)
          m('$i', DateTime(2026, 1, i + 1), sa: 5, goals: {'p1': gs[i]}),
      ]);
      expect(s.braces, 2);
      expect(s.hatTricks, 2);
      expect(s.maxGoalsMatch!.goals, 4);
    });

    test('max goals tie picks the most recent', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        m('1', DateTime(2026, 1, 1), sa: 3, goals: {'p1': 3}),
        m('2', DateTime(2026, 2, 1), sa: 3, goals: {'p1': 3}),
      ]);
      expect(s.maxGoalsMatch!.date, DateTime(2026, 2, 1));
    });

    test('no goals means no max goals match', () {
      final s = PlayerStatsSummary.compute(
          playerId: 'p1', allMatches: [m('1', DateTime(2026, 1, 1), sa: 2)]);
      expect(s.maxGoalsMatch, isNull);
    });
  });

  group('results extras', () {
    test('average goal difference from the player side', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        m('1', DateTime(2026, 1, 1), sa: 5, sb: 2),
        m('2', DateTime(2026, 1, 2),
            a: ['y', 'z'], b: ['p1', 'x'], sa: 1, sb: 3),
        m('3', DateTime(2026, 1, 3)),
      ]);
      expect(s.avgGoalDiff, closeTo(5 / 3, 1e-9));
      expect(s.avgGoalsFor, closeTo(8 / 3, 1e-9));
      expect(s.avgGoalsAgainst, closeTo(1.0, 1e-9));
    });

    test('margin bands', () {
      final results = [
        (3, 2), (3, 1), (3, 0), (6, 0), // wins: 1, 2, 3, 6
        (0, 1), (1, 2), (0, 4), // losses: 1, 1, 4
      ];
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        for (var i = 0; i < results.length; i++)
          m('$i', DateTime(2026, 1, i + 1),
              sa: results[i].$1, sb: results[i].$2),
      ]);
      expect(s.winsByMargin,
          {MarginBand.narrow: 1, MarginBand.clear: 1, MarginBand.wide: 2});
      expect(s.lossesByMargin,
          {MarginBand.narrow: 2, MarginBand.clear: 0, MarginBand.wide: 1});
    });

    test('only draws -> all bands zero', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        m('1', DateTime(2026, 1, 1), sa: 2, sb: 2),
        m('2', DateTime(2026, 1, 2), sa: 2, sb: 2),
      ]);
      const zero = {
        MarginBand.narrow: 0,
        MarginBand.clear: 0,
        MarginBand.wide: 0
      };
      expect(s.winsByMargin, zero);
      expect(s.lossesByMargin, zero);
      expect(s.avgGoalDiff, 0.0);
    });

    test('no matches -> zeros with all keys', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: []);
      expect(s.avgGoalDiff, 0.0);
      expect(s.winsByMargin.length, 3);
      expect(s.lossesByMargin.length, 3);
    });
  });
  group('records', () {
    DateTime d(int i) => DateTime(2026, 1, i);

    PlayerStatsSummary withOutcomes(String outcomes, List<int> goals) {
      return PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        for (var i = 0; i < outcomes.length; i++)
          res('m$i', d(i + 1), outcomes[i], goals: {'p1': goals[i]}),
      ]);
    }

    test('longest streaks with dates', () {
      final s = withOutcomes('VVSVVVPSS', [1, 1, 0, 1, 0, 0, 2, 1, 1]);
      expect(s.longestWinStreak, (length: 3, start: d(4), end: d(6)));
      expect(s.longestUnbeatenStreak, (length: 4, start: d(4), end: d(7)));
      expect(s.longestLossStreak, (length: 2, start: d(8), end: d(9)));
      expect(s.longestScoringStreak, (length: 3, start: d(7), end: d(9)));
      expect(s.longestUnbeatenStreak!.length, s.bestUnbeaten);
    });

    test('ties pick the most recent streak', () {
      final s = withOutcomes('VVSVV', [0, 0, 0, 0, 0]);
      expect(s.longestWinStreak!.length, 2);
      expect(s.longestWinStreak!.start, d(4));
    });

    test('single match gives length-1 streaks with start == end', () {
      final s = withOutcomes('V', [1]);
      expect(s.longestWinStreak, (length: 1, start: d(1), end: d(1)));
      expect(s.longestScoringStreak, (length: 1, start: d(1), end: d(1)));
      expect(s.longestLossStreak, isNull);
    });

    test('no matches -> null streaks and matches', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: []);
      expect(s.longestWinStreak, isNull);
      expect(s.longestUnbeatenStreak, isNull);
      expect(s.bestVoteMatch, isNull);
      expect(s.mostGoalsMatch, isNull);
    });

    test('best vote match tie-breaks on goals then recency', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        res('a', d(1), 'V', votes: {'p1': 8}, goals: {'p1': 1}),
        res('b', d(2), 'V', votes: {'p1': 8}, goals: {'p1': 2}),
        res('c', d(3), 'V', votes: {'p1': 7}, goals: {'p1': 3}),
      ]);
      expect(s.bestVoteMatch!.id, 'b');
      final t = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        res('a', d(1), 'V', votes: {'p1': 8}, goals: {'p1': 1}),
        res('b', d(2), 'V', votes: {'p1': 8}, goals: {'p1': 1}),
      ]);
      expect(t.bestVoteMatch!.id, 'b');
    });

    test('most goals match tie-breaks on vote (absent = -inf) then recency',
        () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        res('a', d(1), 'V', votes: {'p1': 6}, goals: {'p1': 2}),
        res('b', d(2), 'V', goals: {'p1': 2}),
        res('c', d(3), 'V', votes: {'p1': 5}, goals: {'p1': 2}),
        res('d', d(4), 'V', votes: {'p1': 9}, goals: {'p1': 1}),
      ]);
      expect(s.mostGoalsMatch!.id, 'a');
      final t = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        res('a', d(1), 'V', goals: {'p1': 2}),
        res('b', d(2), 'V', goals: {'p1': 2}),
      ]);
      expect(t.mostGoalsMatch!.id, 'b');
    });

    test('most goals match is null when the player never scored', () {
      final s = PlayerStatsSummary.compute(playerId: 'p1', allMatches: [
        res('a', d(1), 'V', votes: {'p1': 7}),
      ]);
      expect(s.mostGoalsMatch, isNull);
      expect(s.bestVoteMatch!.id, 'a');
    });
  });
}
