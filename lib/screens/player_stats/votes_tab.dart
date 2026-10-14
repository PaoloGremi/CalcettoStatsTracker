part of '../player_stats_screen.dart';

/// Voti: andamento, distribuzione, mensile, per risultato, consistenza, trend.
class _VotesTab extends StatelessWidget {
  final PlayerModel player;
  final PlayerStatsSummary summary;

  const _VotesTab({required this.player, required this.summary});

  @override
  Widget build(BuildContext context) {
    final votePoints = summary.votePoints
        .map((p) => FlSpot(p.matchIndex.toDouble(), p.vote))
        .toList();
    final dateLabels =
        summary.matches.map((m) => formatShortDate(m.date)).toList();
    final matches = summary.matches;
    final votedGames = summary.votedGames;
    final avgVote = summary.avgVote;
    final bestVote = summary.bestVote;
    final worstVote = summary.worstVote;
    final voteDistribution = summary.voteDistribution;
    final avgVoteByMonth = summary.avgVoteByMonth;
    final sortedVoteMonthKeys = avgVoteByMonth.keys.toList()..sort();
    final movingAvgPoints = summary.movingAvgVotes
        .map((p) => FlSpot(p.matchIndex.toDouble(), p.vote))
        .toList();
    final votesByOutcome = summary.votesByOutcome;
    double avg0(List<double> list) =>
        list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;
    final avgVoteWin = avg0(votesByOutcome[MatchOutcome.win]!);
    final avgVoteDraw = avg0(votesByOutcome[MatchOutcome.draw]!);
    final avgVoteLoss = avg0(votesByOutcome[MatchOutcome.loss]!);

    final sections = <Widget>[
      // ── Grafico voti nel tempo ────────────────────────
      if (votePoints.length >= 2) ...[
        const FifaSectionHeader('Andamento Voti', accent: AppTheme.accentGold),
        _ChartCard(
          child: LineChart(
            LineChartData(
              minY: 1,
              maxY: 10,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
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
                    interval: 2,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval:
                        (votePoints.length / 5).ceilToDouble().clamp(1, 99),
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= dateLabels.length) {
                        return const SizedBox();
                      }
                      return Text(
                        dateLabels[i],
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 9),
                      );
                    },
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: votePoints,
                  isCurved: true,
                  color: AppTheme.accentGold,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 4,
                      color: AppTheme.accentGold,
                      strokeWidth: 1.5,
                      strokeColor: AppTheme.bg,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.accentGold.withValues(alpha: 0.08),
                  ),
                ),
                // Linea media tratteggiata
                if (avgVote > 0)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, avgVote),
                      FlSpot((matches.length - 1).toDouble(), avgVote),
                    ],
                    isCurved: false,
                    color: AppTheme.accentGold.withValues(alpha: 0.35),
                    barWidth: 1,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    if (s.barIndex == 1) {
                      return null; // nascondi tooltip media
                    }
                    final i = s.x.toInt();
                    final date = i < dateLabels.length ? dateLabels[i] : '';
                    return LineTooltipItem(
                      '$date\n${s.y.toStringAsFixed(1)}',
                      const TextStyle(
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: FifaLabel(
            '— media ${avgVote.toStringAsFixed(1)}',
            color: AppTheme.accentGold.withValues(alpha: 0.5),
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 24),
      ],

      // ── Grafico: Distribuzione Voti ──────────────────
      if (votePoints.length >= 3)
        ..._section(
            'Distribuzione Voti',
            AppTheme.accentGold,
            _ChartCard(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (voteDistribution.values.reduce((a, b) => a > b ? a : b) +
                              1)
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
                        reservedSize: 22,
                        getTitlesWidget: (v, _) {
                          final labels = ['1-2', '3-4', '5-6', '7-8', '9-10'];
                          final i = v.toInt();
                          if (i < 0 || i >= labels.length) {
                            return const SizedBox();
                          }
                          return Text(labels[i],
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
                  barGroups: voteDistribution.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((e) {
                    final i = e.key;
                    final count = e.value.value;
                    // colore caldo per i voti alti
                    final colors = [
                      AppTheme.accentRed,
                      AppTheme.accentOrange,
                      AppTheme.accentGold,
                      AppTheme.accentGreen,
                      AppTheme.accentBlue,
                    ];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: colors[i],
                          width: 32,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }).toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) {
                        final labels = ['1-2', '3-4', '5-6', '7-8', '9-10'];
                        return BarTooltipItem(
                          'Voto ${labels[group.x]}\n${rod.toY.toInt()} volte',
                          const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
              ),
            )),

      // ── Grafico: Voto Medio per Mese ─────────────────
      if (sortedVoteMonthKeys.length >= 2)
        ..._section(
            'Voto Medio per Mese',
            AppTheme.accentGold,
            _ChartCard(
              child: LineChart(
                LineChartData(
                  minY: 1,
                  maxY: 10,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: AppTheme.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= sortedVoteMonthKeys.length) {
                            return const SizedBox();
                          }
                          final step = (sortedVoteMonthKeys.length / 4)
                              .ceil()
                              .clamp(1, 99);
                          if (i % step != 0) return const SizedBox();
                          final parts = sortedVoteMonthKeys[i].split('-');
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: sortedVoteMonthKeys
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                              e.key.toDouble(), avgVoteByMonth[e.value]!))
                          .toList(),
                      isCurved: true,
                      color: AppTheme.accentGold,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.accentGold,
                          strokeWidth: 1.5,
                          strokeColor: AppTheme.bg,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.accentGold.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final i = s.x.toInt();
                        if (i < 0 || i >= sortedVoteMonthKeys.length) {
                          return null;
                        }
                        final parts = sortedVoteMonthKeys[i].split('-');
                        final dt =
                            DateTime(int.parse(parts[0]), int.parse(parts[1]));
                        final label =
                            DateFormat('MMM yyyy', 'it_IT').format(dt);
                        return LineTooltipItem(
                          '$label\n${s.y.toStringAsFixed(1)}',
                          const TextStyle(
                              color: AppTheme.accentGold,
                              fontWeight: FontWeight.w800,
                              fontSize: 12),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            )),

      // ── Grafico: Voto Medio per Risultato ────────────
      if (votePoints.isNotEmpty &&
          (votesByOutcome[MatchOutcome.win]!.isNotEmpty ||
              votesByOutcome[MatchOutcome.loss]!.isNotEmpty))
        ..._section(
            'Voto per Risultato',
            AppTheme.accentBlue,
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 160,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        minY: 0,
                        maxY: 10,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 2,
                          getDrawingHorizontalLine: (_) =>
                              FlLine(color: AppTheme.border, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 2,
                              reservedSize: 28,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (v, _) {
                                const labels = [
                                  'Vittorie',
                                  'Pareggi',
                                  'Sconfitte'
                                ];
                                final i = v.toInt();
                                if (i < 0 || i >= labels.length) {
                                  return const SizedBox();
                                }
                                return Text(labels[i],
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 9));
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [
                            BarChartRodData(
                              toY: avgVoteWin,
                              color: AppTheme.accentGreen,
                              width: 36,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ]),
                          BarChartGroupData(x: 1, barRods: [
                            BarChartRodData(
                              toY: avgVoteDraw,
                              color: AppTheme.accentGold,
                              width: 36,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ]),
                          BarChartGroupData(x: 2, barRods: [
                            BarChartRodData(
                              toY: avgVoteLoss,
                              color: AppTheme.accentRed,
                              width: 36,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ]),
                        ],
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, _, rod, __) {
                              const labels = [
                                'Vittorie',
                                'Pareggi',
                                'Sconfitte'
                              ];
                              final avg = rod.toY;
                              if (avg == 0) return null;
                              return BarTooltipItem(
                                '${labels[group.x]}\n${avg.toStringAsFixed(1)}',
                                const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Legenda con valori
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ResultAvgBadge(
                          label: 'Vittorie',
                          avg: avgVoteWin,
                          color: AppTheme.accentGreen,
                          count: votesByOutcome[MatchOutcome.win]!.length),
                      _ResultAvgBadge(
                          label: 'Pareggi',
                          avg: avgVoteDraw,
                          color: AppTheme.accentGold,
                          count: votesByOutcome[MatchOutcome.draw]!.length),
                      _ResultAvgBadge(
                          label: 'Sconfitte',
                          avg: avgVoteLoss,
                          color: AppTheme.accentRed,
                          count: votesByOutcome[MatchOutcome.loss]!.length),
                    ],
                  ),
                ],
              ),
            )),

      // ── Consistenza Voto ──────────────────────────────
      if (votedGames >= 2)
        ..._section(
            'Consistenza',
            AppTheme.accentBlue,
            _ConsistencyCard(
              avgVote: avgVote,
              bestVote: bestVote,
              worstVote: worstVote,
              votePoints: votePoints,
            )),

      // ── Trend Voto con Media Mobile ───────────────────
      if (votePoints.length >= PlayerStatsSummary.movingWindow) ...[
        const FifaSectionHeader('Trend Voto (Media Mobile)',
            accent: AppTheme.accentGold),
        _ChartCard(
          child: LineChart(
            LineChartData(
              minY: 1,
              maxY: 10,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: AppTheme.border, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 10),
                    ),
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
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                // Voti raw (linea grigia sottile)
                LineChartBarData(
                  spots: votePoints,
                  isCurved: false,
                  color: AppTheme.textMuted.withValues(alpha: 0.35),
                  barWidth: 1.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 2.5,
                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                      strokeWidth: 0,
                      strokeColor: Colors.transparent,
                    ),
                  ),
                ),
                // Media mobile (linea colorata principale)
                LineChartBarData(
                  spots: movingAvgPoints,
                  isCurved: true,
                  color: AppTheme.accentGold,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.accentGold.withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final i = s.x.toInt();
                    final date = i < dateLabels.length ? dateLabels[i] : '';
                    final isMovingAvg = s.barIndex == 1;
                    return LineTooltipItem(
                      isMovingAvg
                          ? 'Media mobile\n${s.y.toStringAsFixed(1)}'
                          : '$date  ${s.y.toStringAsFixed(1)}',
                      TextStyle(
                        color: isMovingAvg
                            ? AppTheme.accentGold
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        // Legenda
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 24,
                  height: 2,
                  color: AppTheme.textMuted.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              const Text('Voto singola partita',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              const SizedBox(width: 18),
              Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold,
                    borderRadius: BorderRadius.circular(2),
                  )),
              const SizedBox(width: 6),
              const Text('Media mobile (5 partite)',
                  style: TextStyle(
                      color: AppTheme.accentGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    ];
    if (sections.isEmpty) return const _EmptyTab();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: sections,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Consistenza Voto
// ─────────────────────────────────────────────────────────────

class _ConsistencyCard extends StatelessWidget {
  final double avgVote;
  final double bestVote;
  final double worstVote;
  final List<FlSpot> votePoints;

  const _ConsistencyCard({
    required this.avgVote,
    required this.bestVote,
    required this.worstVote,
    required this.votePoints,
  });

  String _consistencyLabel(double stdDev) {
    if (stdDev < 1.0) return 'Molto costante';
    if (stdDev < 1.8) return 'Abbastanza costante';
    if (stdDev < 2.5) return 'Variabile';
    return 'Molto variabile';
  }

  Color _consistencyColor(double stdDev) {
    if (stdDev < 1.0) return AppTheme.accentGreen;
    if (stdDev < 1.8) return AppTheme.accentBlue;
    if (stdDev < 2.5) return AppTheme.accentGold;
    return AppTheme.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    // Deviazione standard
    final n = votePoints.length;
    final mean = avgVote;
    final realStdDev = n > 1
        ? math.sqrt(
            votePoints
                    .map((s) => (s.y - mean) * (s.y - mean))
                    .reduce((a, b) => a + b) /
                (n - 1),
          )
        : 0.0;

    final range = bestVote - worstVote;
    final label = _consistencyLabel(realStdDev);
    final labelColor = _consistencyColor(realStdDev);

    // Posizione del marker media sulla barra (1–10)
    final markerPct = ((avgVote - 1.0) / 9.0).clamp(0.0, 1.0);
    final leftPct = ((worstVote - 1.0) / 9.0).clamp(0.0, 1.0);
    final rightPct = 1.0 - ((bestVote - 1.0) / 9.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etichetta consistenza
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: labelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: labelColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'range ${range.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barra range voto
          LayoutBuilder(
            builder: (context, constraints) {
              final barW = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Sfondo
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.border.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Range colorato
                  Positioned(
                    left: leftPct * barW,
                    right: rightPct * barW,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppTheme.accentBlue.withValues(alpha: 0.5),
                            width: 1),
                      ),
                    ),
                  ),
                  // Marker media
                  Positioned(
                    left: markerPct * barW - 2,
                    top: -4,
                    child: Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Label media sopra
                  Positioned(
                    left: (markerPct * barW - 14).clamp(0, barW - 28),
                    top: -20,
                    child: Text(
                      avgVote.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          // Etichette min/max
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('min ${worstVote.toStringAsFixed(1)}',
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
              Text('media',
                  style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
              Text('max ${bestVote.toStringAsFixed(1)}',
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 16),

          // Tre stat box
          Row(
            children: [
              Expanded(
                child: _ConsistStat(
                  label: 'Partite votate',
                  value: '${votePoints.length}',
                  color: AppTheme.textSecondary,
                ),
              ),
              Expanded(
                child: _ConsistStat(
                  label: 'Voto medio',
                  value: avgVote.toStringAsFixed(1),
                  color: AppTheme.accentBlue,
                ),
              ),
              Expanded(
                child: _ConsistStat(
                  label: 'Dev. std.',
                  value: realStdDev.toStringAsFixed(2),
                  color: labelColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
