part of '../player_stats_screen.dart';

/// Serie record: vittorie, imbattibilità, sconfitte e partite a segno.
class _RecordStreaksCard extends StatelessWidget {
  final PlayerStatsSummary summary;

  const _RecordStreaksCard({required this.summary});

  static String _range(Streak s) => s.start == s.end
      ? formatShortDate(s.start)
      : '${formatShortDate(s.start)} → ${formatShortDate(s.end)}';

  Widget _cell(String label, Streak? s, Color color) => Expanded(
        child: Column(
          children: [
            SizedBox(
              height: 80,
              child: Row(children: [
                _StatBox(
                    label: label,
                    value: s == null ? '—' : '${s.length}',
                    color: color),
              ]),
            ),
            const SizedBox(height: 4),
            Text(
              s == null ? '' : _range(s),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          _cell('VITTORIE', summary.longestWinStreak, AppTheme.accentGreen),
          const SizedBox(width: 10),
          _cell(
              'IMBATTUTO', summary.longestUnbeatenStreak, AppTheme.accentBlue),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _cell('SCONFITTE', summary.longestLossStreak, AppTheme.accentRed),
          const SizedBox(width: 10),
          _cell('A SEGNO', summary.longestScoringStreak, AppTheme.accentGold),
        ]),
      ],
    );
  }
}
