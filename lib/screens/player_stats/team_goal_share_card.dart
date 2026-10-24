part of '../player_stats_screen.dart';

/// Quota dei gol della squadra segnati dal giocatore (ciambella).
class _TeamGoalShareCard extends StatelessWidget {
  final PlayerStatsSummary summary;

  const _TeamGoalShareCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final share = summary.teamGoalShare ?? 0;
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 48,
                  sectionsSpace: 2,
                  startDegreeOffset: -90,
                  sections: [
                    PieChartSectionData(
                      value: share,
                      color: AppTheme.accentRed,
                      showTitle: false,
                      radius: 22,
                    ),
                    PieChartSectionData(
                      value: (1 - share).clamp(0.0, 1.0),
                      color: AppTheme.surfaceAlt,
                      showTitle: false,
                      radius: 22,
                    ),
                  ],
                ),
              ),
              Text(
                '${(share * 100).round()}%',
                style: TextStyle(
                  color: AppTheme.accentRed,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FifaLabel(
          '${summary.totalGoals} gol su ${summary.teamGoals} della squadra',
          color: AppTheme.textSecondary,
          fontSize: 11,
        ),
      ],
    );
  }
}
