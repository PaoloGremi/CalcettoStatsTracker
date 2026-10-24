part of '../player_stats_screen.dart';

/// Partite per giorno della settimana, con % vittorie e voto medio sotto
/// ogni barra.
class _WeekdayCard extends StatelessWidget {
  final List<WeekdayStat> stats;

  const _WeekdayCard({required this.stats});

  static const _labels = ['LUN', 'MAR', 'MER', 'GIO', 'VEN', 'SAB', 'DOM'];

  @override
  Widget build(BuildContext context) {
    final maxGames = stats.map((s) => s.games).reduce(math.max);
    final mutedStyle = TextStyle(color: AppTheme.textMuted, fontSize: 9);
    return _ChartCard(
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxGames + 1).toDouble(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= stats.length) return const SizedBox();
                  final s = stats[i];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      children: [
                        Text(_labels[s.weekday - 1],
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                        Text('${s.winPct}% V', style: mutedStyle),
                        Text(s.avgVote?.toStringAsFixed(1) ?? '—',
                            style: mutedStyle),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < stats.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: stats[i].games.toDouble(),
                  color: AppTheme.accentBlue,
                  width: 18,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ]),
          ],
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${stats[group.x].games} partite',
                TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
