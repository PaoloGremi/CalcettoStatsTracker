import 'package:flutter/material.dart';
import 'player_stats_screen.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../models/player_model.dart';
import '../widgets/player_avatar.dart';
import '../theme/app_theme.dart';

enum _SortMode {
  avgVote,
  mvp,
  hustle,
  bestGoal,
  goals,
  matches
} // ✅ aggiunto matches

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _SortMode _mode = _SortMode.matches;

  static const _modes = [
    {'value': _SortMode.avgVote, 'label': 'Voto Medio', 'emoji': '⭐'},
    {'value': _SortMode.mvp, 'label': 'MVP', 'emoji': '👑'},
    {'value': _SortMode.hustle, 'label': 'Più Combattivo', 'emoji': '🔥'},
    {'value': _SortMode.bestGoal, 'label': 'Best Goal', 'emoji': '⚽'},
    {'value': _SortMode.goals, 'label': 'Gol Segnati', 'emoji': '🥅'}, // ✅
    {
      'value': _SortMode.matches,
      'label': 'Partite Giocate',
      'emoji': '📊'
    }, // ✅
  ];

  Color _voteColor(double avg) {
    if (avg >= 8.0) return AppTheme.accentGreen;
    if (avg >= 6.5) return AppTheme.accentGold;
    if (avg >= 5.0) return AppTheme.accentOrange;
    return AppTheme.accentRed;
  }

  Color _modeAccent() {
    switch (_mode) {
      case _SortMode.avgVote:
        return AppTheme.accentBlue;
      case _SortMode.mvp:
        return AppTheme.accentGold;
      case _SortMode.hustle:
        return AppTheme.accentOrange;
      case _SortMode.bestGoal:
        return AppTheme.accentGreen;
      case _SortMode.goals:
        return AppTheme.accentRed; // ✅
      case _SortMode.matches:
        return AppTheme.accentBlue; // ✅ (colore neutro, stat di presenza)
    }
  }

  num _sortValue(PlayerModel player, Map<String, Map<String, dynamic>> stats) {
    switch (_mode) {
      case _SortMode.avgVote:
        return stats[player.id]!['avgVote'] as double;
      case _SortMode.mvp:
        return player.mvpCount;
      case _SortMode.hustle:
        return player.hustleCount;
      case _SortMode.bestGoal:
        return player.bestGoalCount;
      case _SortMode.goals:
        return stats[player.id]!['goals'] as int; // ✅ calcolato dalle partite
      case _SortMode.matches:
        return stats[player.id]!['games'] as int; // ✅ partite giocate
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context);
    final players = data.getAllPlayers();
    final matches = data.getAllMatches();

    // Calcola statistiche voto per ogni giocatore
    final stats = <String, Map<String, dynamic>>{};
    for (final player in players) {
      int gamesPlayed = 0;
      double totalVotes = 0;
      int votesCount = 0;
      for (final match in matches) {
        if (match.teamA.contains(player.id) ||
            match.teamB.contains(player.id)) {
          gamesPlayed++;
          if (match.votes.containsKey(player.id)) {
            totalVotes += match.votes[player.id]!;
            votesCount++;
          }
        }
      }
      // ✅ calcola gol totali direttamente dalle partite (fonte di verità)
      int goalsFromMatches = 0;
      for (final match in matches) {
        goalsFromMatches += match.goals[player.id] ?? 0;
      }
      stats[player.id] = {
        'games': gamesPlayed,
        'avgVote': votesCount > 0 ? totalVotes / votesCount : 0.0,
        'votes': votesCount,
        'goals': goalsFromMatches, // ✅
      };
    }

    // Ordina per modalità selezionata (decrescente), poi per nome
    final sorted = [...players]..sort((a, b) {
        final diff = _sortValue(b, stats).compareTo(_sortValue(a, stats));
        if (diff != 0) return diff;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final accent = _modeAccent();

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
      body: Column(
        children: [
          // ── Dropdown selezione classifica ─────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                    width: 3,
                    height: 18,
                    color: accent,
                    margin: const EdgeInsets.only(right: 10)),
                FifaLabel('Classifica per',
                    color: AppTheme.textSecondary, fontSize: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_SortMode>(
                        value: _mode,
                        isDense: true,
                        dropdownColor: AppTheme.surfaceAlt,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: accent, size: 18),
                        items: _modes.map((m) {
                          final v = m['value'] as _SortMode;
                          final isSelected = v == _mode;
                          return DropdownMenuItem<_SortMode>(
                            value: v,
                            child: Row(
                              children: [
                                Text(m['emoji'] as String,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(
                                  (m['label'] as String).toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? accent
                                        : AppTheme.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _mode = v);
                        },
                        selectedItemBuilder: (_) => _modes
                            .map((m) => Row(
                                  children: [
                                    Text(m['emoji'] as String,
                                        style: const TextStyle(fontSize: 15)),
                                    const SizedBox(width: 8),
                                    Text(
                                      (m['label'] as String).toUpperCase(),
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Lista giocatori ───────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemCount: sorted.length,
              itemBuilder: (context, i) {
                final player = sorted[i];
                final rank = i + 1;
                final isFirst = i == 0;
                final isSecond = i == 1;
                final isThird = i == 2;
                const podiumGold = Color(0xFFFFD700);
                const podiumSilver = Color(0xFFB8B8B8);
                const podiumBronze = Color(0xFFCD7F32);
                final podiumColor = isFirst
                    ? podiumGold
                    : isSecond
                        ? podiumSilver
                        : isThird
                            ? podiumBronze
                            : null;
                final games = stats[player.id]!['games'] as int;
                final avgVote = stats[player.id]!['avgVote'] as double;
                final isEmpty = _sortValue(player, stats) == 0;

                final boxColor = switch (_mode) {
                  _SortMode.avgVote => _voteColor(avgVote),
                  _SortMode.mvp => AppTheme.accentGold,
                  _SortMode.hustle => AppTheme.accentOrange,
                  _SortMode.bestGoal => AppTheme.accentGreen,
                  _SortMode.goals => AppTheme.accentRed, // ✅
                  _SortMode.matches => AppTheme.accentBlue, // ✅
                };

                final boxMain = switch (_mode) {
                  _SortMode.avgVote => avgVote.toStringAsFixed(1),
                  _SortMode.mvp => '${player.mvpCount}',
                  _SortMode.hustle => '${player.hustleCount}',
                  _SortMode.bestGoal => '${player.bestGoalCount}',
                  _SortMode.goals =>
                    '${(stats[player.id]!["goals"] as int)}', // ✅
                  _SortMode.matches =>
                    '${(stats[player.id]!["games"] as int)}', // ✅
                };

                final boxSub = switch (_mode) {
                  _SortMode.avgVote => 'MEDIA',
                  _SortMode.mvp => '👑',
                  _SortMode.hustle => '🔥',
                  _SortMode.bestGoal => '⚽',
                  _SortMode.goals => '🥅', // ✅
                  _SortMode.matches => '📊', // ✅
                };

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerStatsScreen(player: player),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      gradient: podiumColor != null && !isEmpty
                          ? LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                podiumColor.withValues(
                                    alpha: isFirst ? 0.18 : 0.10),
                                podiumColor.withValues(alpha: 0.04),
                              ],
                            )
                          : null,
                      color: podiumColor == null || isEmpty
                          ? AppTheme.surface
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: podiumColor != null && !isEmpty
                            ? podiumColor.withValues(alpha: isFirst ? 0.6 : 0.4)
                            : AppTheme.border,
                        width: podiumColor != null ? 1.5 : 1,
                      ),
                      boxShadow: podiumColor != null && !isEmpty
                          ? [
                              BoxShadow(
                                color: podiumColor.withValues(
                                    alpha: isFirst ? 0.20 : 0.10),
                                blurRadius: isFirst ? 20 : 10,
                              )
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // Rank
                          SizedBox(
                            width: 28,
                            child: Text(
                              isFirst
                                  ? '🥇'
                                  : isSecond
                                      ? '🥈'
                                      : isThird
                                          ? '🥉'
                                          : '#$rank',
                              style: TextStyle(
                                color: podiumColor ?? AppTheme.textMuted,
                                fontSize: podiumColor != null ? 20 : 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PlayerAvatar(
                              name: player.name,
                              icon: player.icon,
                              imagePath: player.imagePath,
                              radius: 24),
                          const SizedBox(width: 14),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.name.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    FifaBadge(player.role,
                                        color: switch (player.role) {
                                          'P' => AppTheme.accentGold,
                                          'D' => AppTheme.accentBlue,
                                          'C' => AppTheme.accentGreen,
                                          'A' => AppTheme.accentRed,
                                          _ => AppTheme.textMuted,
                                        }),
                                    const SizedBox(width: 6),
                                    Text('$games partite',
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11)),
                                  ],
                                ),
                                // Badge premi secondari + gol
                                if (player.mvpCount > 0 ||
                                    player.hustleCount > 0 ||
                                    player.bestGoalCount > 0 ||
                                    (stats[player.id]!['goals'] as int) >
                                        0) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (player.mvpCount > 0) ...[
                                        _AwardCounter(
                                            emoji: '👑',
                                            count: player.mvpCount,
                                            color: AppTheme.accentGold,
                                            highlight: _mode == _SortMode.mvp),
                                        const SizedBox(width: 5),
                                      ],
                                      if (player.hustleCount > 0) ...[
                                        _AwardCounter(
                                            emoji: '🔥',
                                            count: player.hustleCount,
                                            color: AppTheme.accentOrange,
                                            highlight:
                                                _mode == _SortMode.hustle),
                                        const SizedBox(width: 5),
                                      ],
                                      if (player.bestGoalCount > 0) ...[
                                        _AwardCounter(
                                            emoji: '⚽',
                                            count: player.bestGoalCount,
                                            color: AppTheme.accentGreen,
                                            highlight:
                                                _mode == _SortMode.bestGoal),
                                        const SizedBox(width: 5),
                                      ],
                                      // ✅ Gol totali calcolati dalle partite
                                      if ((stats[player.id]!['goals'] as int) >
                                          0)
                                        _AwardCounter(
                                            emoji: '🥅',
                                            count: stats[player.id]!['goals']
                                                as int,
                                            color: AppTheme.accentRed,
                                            highlight:
                                                _mode == _SortMode.goals),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Box metrica principale
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: isEmpty
                                  ? AppTheme.surfaceAlt
                                  : boxColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isEmpty
                                    ? AppTheme.border
                                    : boxColor.withValues(alpha: 0.45),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isEmpty ? '—' : boxMain,
                                  style: TextStyle(
                                    color:
                                        isEmpty ? AppTheme.textMuted : boxColor,
                                    fontSize:
                                        _mode == _SortMode.avgVote ? 20 : 22,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEmpty ? '' : boxSub,
                                  style: TextStyle(
                                    color: isEmpty
                                        ? Colors.transparent
                                        : boxColor.withValues(alpha: 0.6),
                                    fontSize:
                                        _mode == _SortMode.avgVote ? 9 : 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing:
                                        _mode == _SortMode.avgVote ? 1.5 : 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge con contatore e highlight quando è la modalità attiva
class _AwardCounter extends StatelessWidget {
  final String emoji;
  final int count;
  final Color color;
  final bool highlight;
  const _AwardCounter({
    required this.emoji,
    required this.count,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: highlight
              ? color.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight
                ? color.withValues(alpha: 0.6)
                : color.withValues(alpha: 0.25),
            width: highlight ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(
              '×$count',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}
