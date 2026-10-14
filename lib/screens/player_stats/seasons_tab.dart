part of '../player_stats_screen.dart';

/// Stagioni: partite per mese.
class _SeasonsTab extends StatelessWidget {
  final PlayerModel player;
  final PlayerStatsSummary summary;
  final DateTime? today;

  const _SeasonsTab({required this.player, required this.summary, this.today});

  @override
  Widget build(BuildContext context) {
    final matchesByMonth = summary.matchesByMonth;
    final sortedMonthKeys = matchesByMonth.keys.toList()..sort();

    final sections = <Widget>[
      if (summary.activeYears.isNotEmpty)
        ..._section('Mappa Presenze', AppTheme.accentGreen,
            _ActivityHeatmap(summary: summary, today: today ?? DateTime.now())),
      if (summary.weekdayStats.isNotEmpty)
        ..._section('Giorno della Settimana', AppTheme.accentBlue,
            _WeekdayCard(stats: summary.weekdayStats)),
      if (summary.yearStats.length >= 2)
        ..._section('Confronto Anni', AppTheme.accentGold,
            _YearComparisonCard(stats: summary.yearStats)),
      // ── Grafico partite per mese ──────────────────────
      if (sortedMonthKeys.length >= 2)
        ..._section(
            'Partite per Mese',
            AppTheme.accentBlue,
            _ChartCard(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (matchesByMonth.values.reduce((a, b) => a > b ? a : b) +
                          1)
                      .toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppTheme.border,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) {
                          if (v != v.floorToDouble()) {
                            return const SizedBox();
                          }
                          return Text(
                            v.toInt().toString(),
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= sortedMonthKeys.length) {
                            return const SizedBox();
                          }
                          final step =
                              (sortedMonthKeys.length / 5).ceil().clamp(1, 99);
                          if (i % step != 0) return const SizedBox();
                          // "yyyy-MM" -> "mmm yy"
                          final parts = sortedMonthKeys[i].split('-');
                          final dt = DateTime(
                              int.parse(parts[0]), int.parse(parts[1]));
                          return Text(
                            formatMonthYearShort(dt),
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 9),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: sortedMonthKeys.asMap().entries.map((entry) {
                    final i = entry.key;
                    final key = entry.value;
                    final count = matchesByMonth[key]!;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: AppTheme.accentBlue,
                          width: sortedMonthKeys.length > 10 ? 10 : 18,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) {
                        final i = group.x;
                        final key = sortedMonthKeys[i];
                        final parts = key.split('-');
                        final dt =
                            DateTime(int.parse(parts[0]), int.parse(parts[1]));
                        final label = formatMonthYearFull(dt);
                        final count = matchesByMonth[key]!;
                        return BarTooltipItem(
                          '$label\n$count partite',
                          const TextStyle(
                            color: AppTheme.accentBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            )),
    ];
    if (sections.isEmpty) return const _EmptyTab();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: sections,
    );
  }
}
