part of '../player_stats_screen.dart';

/// Vittorie (verde, a destra) e sconfitte (rosso, a sinistra) per margine.
class _MarginsCard extends StatelessWidget {
  final PlayerStatsSummary summary;

  const _MarginsCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final counts = [
      ...summary.winsByMargin.values,
      ...summary.lossesByMargin.values,
    ];
    final maxCount = counts.isEmpty ? 0 : counts.reduce(math.max);
    double frac(int c) => maxCount > 0 ? c / maxCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          for (final band in MarginBand.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  _count(summary.lossesByMargin[band] ?? 0, AppTheme.accentRed),
                  Expanded(
                    child: _bar(frac(summary.lossesByMargin[band] ?? 0),
                        AppTheme.accentRed, Alignment.centerRight),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(band.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: _bar(frac(summary.winsByMargin[band] ?? 0),
                        AppTheme.accentGreen, Alignment.centerLeft),
                  ),
                  _count(summary.winsByMargin[band] ?? 0, AppTheme.accentGreen),
                ],
              ),
            ),
          Text('Pareggi: ${summary.draws}',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _count(int n, Color color) => SizedBox(
        width: 24,
        child: Text('$n',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      );

  Widget _bar(double fraction, Color color, Alignment align) => SizedBox(
        height: 14,
        child: Align(
          alignment: align,
          child: FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      );
}
