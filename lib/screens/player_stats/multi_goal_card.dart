part of '../player_stats_screen.dart';

/// Doppiette, triplette e partita col massimo di gol.
class _MultiGoalCard extends StatelessWidget {
  final PlayerStatsSummary summary;

  const _MultiGoalCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final max = summary.maxGoalsMatch;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatBox(
          label: 'DOPPIETTE',
          value: '${summary.braces}',
          color: AppTheme.accentGold,
        ),
        const SizedBox(width: 10),
        _StatBox(
          label: 'TRIPLETTE+',
          value: '${summary.hatTricks}',
          color: AppTheme.accentGold,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              Row(children: [
                _StatBox(
                  label: 'MAX GOL',
                  value: '${max?.goals ?? 0}',
                  color: AppTheme.accentGold,
                ),
              ]),
              if (max != null) ...[
                const SizedBox(height: 4),
                Text(
                  formatShortDate(max.date),
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
