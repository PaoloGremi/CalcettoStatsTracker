part of '../player_stats_screen.dart';

/// Gol: per partita, cumulativi, per mese.
class _GoalsTab extends StatelessWidget {
  final PlayerModel player;
  final PlayerStatsSummary summary;

  const _GoalsTab({required this.player, required this.summary});

  @override
  Widget build(BuildContext context) {
    final dateLabels =
        summary.matches.map((m) => formatShortDate(m.date)).toList();
    final matches = summary.matches;
    final totalGoals = summary.totalGoals;
    final goalPoints = summary.goalsPerMatch
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();
    final cumulativeGoalPoints = summary.cumulativeGoals
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();
    final goalsByMonth = summary.goalsByMonth;
    final sortedGoalMonthKeys = goalsByMonth.keys.toList()..sort();

    final sections = <Widget>[
      // ── Grafico gol per partita ───────────────────────
      if (totalGoals > 0)
        ..._section(
            'Gol per Partita',
            AppTheme.accentRed,
            _ChartCard(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (goalPoints
                          .map((s) => s.y)
                          .reduce((a, b) => a > b ? a : b) +
                      1),
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
                        reservedSize: 22,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= dateLabels.length) {
                            return const SizedBox();
                          }
                          // mostra solo ogni N label per non sovraffollare
                          final step = (matches.length / 5).ceil().clamp(1, 99);
                          if (i % step != 0) return const SizedBox();
                          return Text(
                            dateLabels[i],
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
                  barGroups: goalPoints.asMap().entries.map((entry) {
                    final i = entry.key;
                    final spot = entry.value;
                    final hasGoal = spot.y > 0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: spot.y == 0
                              ? 0.05
                              : spot.y, // piccolo segno anche per 0
                          color: hasGoal ? AppTheme.accentRed : AppTheme.border,
                          width: matches.length > 15 ? 8 : 16,
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
                        final date = i < dateLabels.length ? dateLabels[i] : '';
                        final goals = goalPoints[i].y.toInt();
                        return BarTooltipItem(
                          '$date\n$goals 🥅',
                          const TextStyle(
                            color: AppTheme.accentRed,
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

      // ── Grafico: Gol Cumulativi nel Tempo ────────────
      if (totalGoals > 0 && cumulativeGoalPoints.length >= 2)
        ..._section(
            'Gol Cumulativi',
            AppTheme.accentRed,
            _ChartCard(
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: AppTheme.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) {
                          if (v != v.floorToDouble()) {
                            return const SizedBox();
                          }
                          return Text(v.toInt().toString(),
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 10));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= dateLabels.length) {
                            return const SizedBox();
                          }
                          final step = (matches.length / 5).ceil().clamp(1, 99);
                          if (i % step != 0) return const SizedBox();
                          return Text(dateLabels[i],
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 9));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: cumulativeGoalPoints,
                      isCurved: false,
                      color: AppTheme.accentRed,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.accentRed.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final i = s.x.toInt();
                        final date = i < dateLabels.length ? dateLabels[i] : '';
                        return LineTooltipItem(
                          '$date\n${s.y.toInt()} gol totali',
                          const TextStyle(
                              color: AppTheme.accentRed,
                              fontWeight: FontWeight.w800,
                              fontSize: 12),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            )),

      // ── Gol per Mese ──────────────────────────────────
      if (sortedGoalMonthKeys.length >= 2 && totalGoals > 0)
        ..._section(
            'Gol per Mese',
            AppTheme.accentRed,
            _ChartCard(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (goalsByMonth.values.reduce((a, b) => a > b ? a : b) + 1)
                          .toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: AppTheme.border, strokeWidth: 1),
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
                          return Text(v.toInt().toString(),
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 10));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= sortedGoalMonthKeys.length) {
                            return const SizedBox();
                          }
                          final step = (sortedGoalMonthKeys.length / 5)
                              .ceil()
                              .clamp(1, 99);
                          if (i % step != 0) return const SizedBox();
                          final parts = sortedGoalMonthKeys[i].split('-');
                          final dt = DateTime(
                              int.parse(parts[0]), int.parse(parts[1]));
                          return Text(formatMonthYearShort(dt),
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 9));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: sortedGoalMonthKeys.asMap().entries.map((entry) {
                    final i = entry.key;
                    final key = entry.value;
                    final count = goalsByMonth[key] ?? 0;
                    final hasGoals = count > 0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: count == 0 ? 0.05 : count.toDouble(),
                          color:
                              hasGoals ? AppTheme.accentRed : AppTheme.border,
                          width: sortedGoalMonthKeys.length > 10 ? 10 : 18,
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
                        final key = sortedGoalMonthKeys[i];
                        final parts = key.split('-');
                        final dt =
                            DateTime(int.parse(parts[0]), int.parse(parts[1]));
                        final label = formatMonthYearFull(dt);
                        final count = goalsByMonth[key] ?? 0;
                        return BarTooltipItem(
                          '$label\n$count ⚽',
                          const TextStyle(
                              color: AppTheme.accentRed,
                              fontWeight: FontWeight.w800,
                              fontSize: 12),
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
