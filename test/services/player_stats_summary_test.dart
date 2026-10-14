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
}
