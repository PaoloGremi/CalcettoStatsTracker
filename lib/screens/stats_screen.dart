import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../widgets/player_avatar.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  Color _voteColor(double avg) {
    if (avg >= 8.0) return AppTheme.accentGreen;
    if (avg >= 6.5) return AppTheme.accentGold;
    if (avg >= 5.0) return AppTheme.accentOrange;
    return AppTheme.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final players = data.getAllPlayers();
    final matches = data.getAllMatches();

    final stats = <String, Map<String, dynamic>>{};
    for (var player in players) {
      int gamesPlayed = 0;
      double totalVotes = 0;
      int votesCount = 0;
      for (var match in matches) {
        if (match.teamA.contains(player.id) || match.teamB.contains(player.id)) {
          gamesPlayed++;
          if (match.votes.containsKey(player.id)) {
            totalVotes += match.votes[player.id]!;
            votesCount++;
          }
        }
      }
      stats[player.id] = {
        'games': gamesPlayed,
        'avgVote': votesCount > 0 ? totalVotes / votesCount : 0.0,
        'votes': votesCount,
      };
    }

    final sorted = [...players]..sort((a, b) =>
        (stats[b.id]!['avgVote'] as double)
            .compareTo(stats[a.id]!['avgVote'] as double));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const FifaLabel('Statistiche Giocatori',
            color: AppTheme.textPrimary, fontSize: 13),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: sorted.length,
        itemBuilder: (context, i) {
          final player = sorted[i];
          final s = stats[player.id]!;
          final avg = s['avgVote'] as double;
          final games = s['games'] as int;
          final accent = _voteColor(avg);
          final rank = i + 1;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: rank == 1
                    ? AppTheme.accentGold.withOpacity(0.5)
                    : AppTheme.border,
                width: rank == 1 ? 1.5 : 1,
              ),
              boxShadow: rank == 1
                  ? [BoxShadow(
                      color: AppTheme.accentGold.withOpacity(0.12),
                      blurRadius: 16)]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 28,
                    child: Text('#$rank',
                      style: TextStyle(
                        color: rank == 1
                            ? AppTheme.accentGold
                            : AppTheme.textMuted,
                        fontSize: rank == 1 ? 14 : 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PlayerAvatar(player: player, radius: 24),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Badge ruolo + partite
                        Row(
                          children: [
                            FifaBadge(player.role, color: AppTheme.accentBlue),
                            const SizedBox(width: 6),
                            Text('$games partite',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                        // ✅ Badge MVP e Combattivo
                        if (player.mvpCount > 0 || player.hustleCount > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (player.mvpCount > 0) ...[
                                _AwardCounter(
                                  emoji: '👑',
                                  count: player.mvpCount,
                                  color: AppTheme.accentGold,
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (player.hustleCount > 0)
                                _AwardCounter(
                                  emoji: '🔥',
                                  count: player.hustleCount,
                                  color: AppTheme.accentOrange,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Voto medio
                  Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: accent.withOpacity(0.45), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(avg.toStringAsFixed(1),
                          style: TextStyle(
                              color: accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1),
                        ),
                        Text('AVG',
                          style: TextStyle(
                              color: accent.withOpacity(0.6),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Piccolo badge con emoji + contatore
class _AwardCounter extends StatelessWidget {
  final String emoji;
  final int count;
  final Color color;
  const _AwardCounter(
      {required this.emoji, required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text('×$count',
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900)),
      ],
    ),
  );
}
