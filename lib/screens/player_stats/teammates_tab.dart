part of '../player_stats_screen.dart';

/// Compagni: chemistry a bolle e radar.
class _TeammatesTab extends StatelessWidget {
  final PlayerModel player;
  final PlayerStatsSummary summary;

  const _TeammatesTab({required this.player, required this.summary});

  @override
  Widget build(BuildContext context) {
    final matches = summary.matches;
    final totalGames = summary.totalGames;

    final sections = <Widget>[
      // ── Chemistry con gli altri giocatori ────────────────────────
      if (totalGames > 0)
        ..._section(
            'Chemistry con i Compagni',
            AppTheme.accentGreen,
            ChemistryBubbleChart(
              matches: matches,
              player: player,
            )),
      // ── Radar Chemistry ───────────────────────────────────────
      if (totalGames > 0)
        ..._section(
            'Radar Chemistry',
            AppTheme.accentBlue,
            ChemistryRadarChart(
              matches: matches,
              player: player,
            )),
    ];
    if (sections.isEmpty) return const _EmptyTab();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: sections,
    );
  }
}
