part of '../player_stats_screen.dart';

/// Voto relativo: scarto dalla media degli altri votati, per partita.
class _RelativeVoteCard extends StatelessWidget {
  static const int maxBars = 20;

  final PlayerStatsSummary summary;

  const _RelativeVoteCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final all = summary.relativeVotes;
    final recent =
        all.length > maxBars ? all.sublist(all.length - maxBars) : all;
    final maxAbs = recent.map((r) => r.delta.abs()).reduce(math.max);
    final bound = math.max(0.5, (maxAbs * 2).ceil() / 2);
    final avg = summary.avgRelativeVote;
    final avgText = '${avg >= 0 ? '+' : ''}${avg.toStringAsFixed(1)}';

    return Column(
      children: [
        Row(
          children: [
            _StatBox(
              label: 'DELTA MEDIO',
              value: avgText,
              color: avg >= 0 ? AppTheme.accentGreen : AppTheme.accentRed,
            ),
            const SizedBox(width: 10),
            _StatBox(
              label: 'SOPRA MEDIA',
              value: '${summary.aboveAvgPct}%',
              color: AppTheme.accentBlue,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ChartCard(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              minY: -bound,
              maxY: bound,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: bound,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: AppTheme.border, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: bound,
                    getTitlesWidget: (v, _) => Text(
                      v.toStringAsFixed(1),
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: [
                for (int i = 0; i < recent.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: recent[i].delta,
                        color: recent[i].delta > 0
                            ? AppTheme.accentGreen
                            : AppTheme.accentRed,
                        width: 8,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
