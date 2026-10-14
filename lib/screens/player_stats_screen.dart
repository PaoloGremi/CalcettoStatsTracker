import 'dart:io';
import 'dart:math' as math;

import 'package:calcetto_tracker/widgets/chemistry_bubble_chart.dart';
import 'package:calcetto_tracker/widgets/chemistry_radar_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/player_model.dart';
import '../models/match_model.dart';
import '../services/data_service.dart';
import '../services/player_stats_summary.dart';
import '../widgets/player_avatar.dart';
import '../theme/app_theme.dart';
import '../services/player_stats_calculator.dart';
import '../core/util/date_formatters.dart';
import 'match_detail_screen.dart';

part 'player_stats/stats_widgets.dart';
part 'player_stats/overview_tab.dart';
part 'player_stats/votes_tab.dart';
part 'player_stats/relative_vote_card.dart';
part 'player_stats/goals_tab.dart';
part 'player_stats/team_goal_share_card.dart';
part 'player_stats/multi_goal_card.dart';
part 'player_stats/results_tab.dart';
part 'player_stats/goal_diff_card.dart';
part 'player_stats/margins_card.dart';
part 'player_stats/records_tab.dart';
part 'player_stats/record_streaks_card.dart';
part 'player_stats/best_matches_card.dart';
part 'player_stats/teammates_tab.dart';
part 'player_stats/seasons_tab.dart';
part 'player_stats/activity_heatmap.dart';
part 'player_stats/weekday_card.dart';
part 'player_stats/year_comparison_card.dart';

class PlayerStatsScreen extends StatelessWidget {
  final PlayerModel player;

  /// Data di riferimento per la mappa presenze (default: ora). Iniettabile nei test.
  final DateTime? today;

  const PlayerStatsScreen({required this.player, this.today, super.key});

  static const _tabs = [
    (label: 'PANORAMICA', icon: Icons.dashboard_rounded),
    (label: 'VOTI', icon: Icons.star_rounded),
    (label: 'GOL', icon: Icons.sports_soccer_rounded),
    (label: 'RISULTATI', icon: Icons.emoji_events_rounded),
    (label: 'RECORD', icon: Icons.military_tech_rounded),
    (label: 'COMPAGNI', icon: Icons.groups_rounded),
    (label: 'STAGIONI', icon: Icons.calendar_month_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataService>(context, listen: false);
    final summary = PlayerStatsSummary.compute(
      playerId: player.id,
      allMatches: data.getAllMatches(),
    );
    final title =
        FifaLabel(player.name, color: AppTheme.textPrimary, fontSize: 13);

    if (summary.totalGames == 0) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          title: title,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppTheme.border),
          ),
        ),
        body: const Center(
          child: Text(
            'Nessuna partita registrata per questo giocatore.',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          title: title,
          // 7 tab fisse che dividono tutta la larghezza: icona + nome
          // piccolo, ridotto ancora (FittedBox) se non ci sta.
          bottom: TabBar(
            tabAlignment: TabAlignment.fill,
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            indicatorColor: AppTheme.accentGreen,
            labelColor: AppTheme.textPrimary,
            unselectedLabelColor: AppTheme.textMuted,
            dividerColor: AppTheme.border,
            labelStyle: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
            tabs: [
              for (final t in _tabs)
                Tab(
                  height: 52,
                  icon: Icon(t.icon, size: 20),
                  iconMargin: const EdgeInsets.only(bottom: 3),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(t.label, maxLines: 1),
                  ),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            _CompactHeader(player: player, summary: summary),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(player: player, summary: summary),
                  _VotesTab(player: player, summary: summary),
                  _GoalsTab(player: player, summary: summary),
                  _ResultsTab(player: player, summary: summary),
                  _RecordsTab(player: player, summary: summary),
                  _TeammatesTab(player: player, summary: summary),
                  _SeasonsTab(player: player, summary: summary, today: today),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header compatto sopra le tab: avatar, nome, ruolo, partite e voto medio.
class _CompactHeader extends StatelessWidget {
  final PlayerModel player;
  final PlayerStatsSummary summary;

  const _CompactHeader({required this.player, required this.summary});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(bottom: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          children: [
            PlayerAvatar(
                name: player.name,
                icon: player.icon,
                imagePath: player.imagePath,
                radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.totalGames} ${summary.totalGames == 1 ? 'partita' : 'partite'} · '
                    '${summary.votedGames > 0 ? summary.avgVote.toStringAsFixed(1) : '—'} ⭐',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FifaBadge(player.role,
                color: switch (player.role) {
                  'P' => AppTheme.accentGold,
                  'D' => AppTheme.accentBlue,
                  'C' => AppTheme.accentGreen,
                  'A' => AppTheme.accentRed,
                  _ => AppTheme.textMuted,
                }),
          ],
        ),
      );
}
