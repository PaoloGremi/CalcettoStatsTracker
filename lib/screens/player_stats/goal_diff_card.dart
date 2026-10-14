part of '../player_stats_screen.dart';

/// Differenza reti media, gol fatti e subiti a partita.
class _GoalDiffCard extends StatelessWidget {
  final PlayerStatsSummary summary;

  const _GoalDiffCard({required this.summary});

  static String _signed(double v) {
    final s = v.toStringAsFixed(1);
    // Evita "-0.0" e "+0.0".
    if (s == '0.0' || s == '-0.0') return '0.0';
    return v > 0 ? '+$s' : s;
  }

  @override
  Widget build(BuildContext context) {
    final diff = summary.avgGoalDiff;
    final diffColor = diff > 0.05
        ? AppTheme.accentGreen
        : (diff < -0.05 ? AppTheme.accentRed : AppTheme.accentGold);
    return Row(
      children: [
        _StatBox(label: 'DIFF. MEDIA', value: _signed(diff), color: diffColor),
        const SizedBox(width: 10),
        _StatBox(
            label: 'GF / PARTITA',
            value: summary.avgGoalsFor.toStringAsFixed(1),
            color: AppTheme.accentGreen),
        const SizedBox(width: 10),
        _StatBox(
            label: 'GS / PARTITA',
            value: summary.avgGoalsAgainst.toStringAsFixed(1),
            color: AppTheme.accentRed),
      ],
    );
  }
}
