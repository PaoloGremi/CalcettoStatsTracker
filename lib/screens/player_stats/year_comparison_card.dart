part of '../player_stats_screen.dart';

/// Tabella anno per anno; una freccia indica la variazione rispetto all'anno
/// precedente (la riga sotto).
class _YearComparisonCard extends StatelessWidget {
  /// Anno decrescente: la riga successiva è l'anno precedente.
  final List<YearStat> stats;

  const _YearComparisonCard({required this.stats});

  static const _headers = ['ANNO', 'PART.', 'VOTO', 'GOL', 'G/P', '%V', 'MVP'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Table(
        children: [
          TableRow(children: [
            for (final h in _headers)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Center(
                  child: FifaLabel(h, color: AppTheme.textMuted, fontSize: 9),
                ),
              ),
          ]),
          for (int i = 0; i < stats.length; i++) _row(i),
        ],
      ),
    );
  }

  TableRow _row(int i) {
    final s = stats[i];
    final prev = i + 1 < stats.length ? stats[i + 1] : null;
    return TableRow(children: [
      _cell('${s.year}', null, AppTheme.textPrimary),
      _cell('${s.games}', _dir(s.games, prev?.games), AppTheme.textPrimary),
      _cell(
          s.avgVote?.toStringAsFixed(1) ?? '—',
          _dir(_tenths(s.avgVote), _tenths(prev?.avgVote)),
          AppTheme.textPrimary),
      _cell('${s.goals}', _dir(s.goals, prev?.goals), AppTheme.textPrimary),
      _cell(
          s.goalsPerGame.toStringAsFixed(1),
          _dir(_tenths(s.goalsPerGame), _tenths(prev?.goalsPerGame)),
          AppTheme.textPrimary),
      _cell('${s.winPct}%', _dir(s.winPct, prev?.winPct), AppTheme.textPrimary),
      _cell('${s.mvps}', _dir(s.mvps, prev?.mvps), AppTheme.textPrimary),
    ]);
  }

  /// Valore arrotondato a 1 decimale (come mostrato), per confronti coerenti.
  int? _tenths(double? v) => v == null ? null : (v * 10).round();

  /// 1 = salito, -1 = sceso, null = uguale / non confrontabile.
  int? _dir(num? cur, num? prev) {
    if (cur == null || prev == null) return null;
    if ((cur - prev).abs() < 1e-9) return null;
    return cur > prev ? 1 : -1;
  }

  Widget _cell(String text, int? dir, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(text,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w700)),
              if (dir != null)
                Text(dir > 0 ? '▲' : '▼',
                    style: TextStyle(
                        color:
                            dir > 0 ? AppTheme.accentGreen : AppTheme.accentRed,
                        fontSize: 8)),
            ],
          ),
        ),
      );
}
