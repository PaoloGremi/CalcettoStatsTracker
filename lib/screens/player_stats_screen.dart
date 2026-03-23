import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/player.dart';
import '../models/match_model.dart';
import '../data/hive_boxes.dart';
import '../widgets/player_avatar.dart';
import '../theme/app_theme.dart';

class PlayerStatsScreen extends StatelessWidget {
  final Player player;

  const PlayerStatsScreen({required this.player, super.key});

  /// Recupera le partite del giocatore ordinate per data crescente
  List<MatchModel> _playerMatches() {
    final matches = HiveBoxes.matchesBox.values
        .where((m) => m.teamA.contains(player.id) || m.teamB.contains(player.id))
        .toList();
    matches.sort((a, b) => a.date.compareTo(b.date));
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    final matches = _playerMatches();

    // Prepara i dati per i grafici
    final votePoints = <FlSpot>[];
    final goalPoints = <FlSpot>[];
    final dateLabels = <String>[];

    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final vote = m.votes[player.id];
      final goals = m.goals[player.id] ?? 0;
      if (vote != null) votePoints.add(FlSpot(i.toDouble(), vote));
      goalPoints.add(FlSpot(i.toDouble(), goals.toDouble()));
      dateLabels.add(DateFormat('dd/MM', 'it_IT').format(m.date));
    }

    // Statistiche aggregate
    final totalGames = matches.length;
    final votedGames = votePoints.length;
    final avgVote = votedGames > 0
        ? votePoints.map((s) => s.y).reduce((a, b) => a + b) / votedGames
        : 0.0;
    final bestVote = votedGames > 0
        ? votePoints.map((s) => s.y).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final worstVote = votedGames > 0
        ? votePoints.map((s) => s.y).reduce((a, b) => a < b ? a : b)
        : 0.0;
    final totalGoals = goalPoints.map((s) => s.y.toInt()).reduce((a, b) => a + b);


    // ── Vittorie / Pareggi / Sconfitte ───────────────────────
    int wins = 0, draws = 0, losses = 0;
    for (final m in matches) {
      final inTeamA = m.teamA.contains(player.id);
      final playerScore = inTeamA ? m.scoreA : m.scoreB;
      final oppScore    = inTeamA ? m.scoreB : m.scoreA;
      if (playerScore > oppScore) wins++;
      else if (playerScore == oppScore) draws++;
      else losses++;
    }

    // ── Partite per mese ─────────────────────────────────────
    // Mappa "yyyy-MM" -> conteggio partite
    final matchesByMonth = <String, int>{};
    for (final m in matches) {
      final key = DateFormat('yyyy-MM').format(m.date);
      matchesByMonth[key] = (matchesByMonth[key] ?? 0) + 1;
    }
    final sortedMonthKeys = matchesByMonth.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: FifaLabel(player.name, color: AppTheme.textPrimary, fontSize: 13),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: matches.isEmpty
          ? const Center(
              child: Text(
                'Nessuna partita registrata per questo giocatore.',
                style: TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [

                // ── Header giocatore ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      PlayerAvatar(player: player, radius: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FifaBadge(player.role,
                                color: switch (player.role) {
                                  'P' => AppTheme.accentGold,
                                  'D' => AppTheme.accentBlue,
                                  'C' => AppTheme.accentGreen,
                                  'A' => AppTheme.accentRed,
                                  _ => AppTheme.textMuted,
                                }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Statistiche sommario ──────────────────────────
                Row(
                  children: [
                    _StatBox(label: 'PARTITE', value: '$totalGames',
                        color: AppTheme.accentBlue),
                    const SizedBox(width: 8),
                    _StatBox(
                        label: 'VOTO MEDIO',
                        value: votedGames > 0 ? avgVote.toStringAsFixed(1) : '—',
                        color: AppTheme.accentGold),
                    const SizedBox(width: 8),
                    _StatBox(label: 'GOL TOTALI', value: '$totalGoals',
                        color: AppTheme.accentRed),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    _StatBox(
                        label: 'MIGLIOR VOTO',
                        value: votedGames > 0 ? bestVote.toStringAsFixed(1) : '—',
                        color: AppTheme.accentGreen),
                    const SizedBox(width: 8),
                    _StatBox(
                        label: 'PEGGIOR VOTO',
                        value: votedGames > 0 ? worstVote.toStringAsFixed(1) : '—',
                        color: AppTheme.accentOrange),
                    const SizedBox(width: 8),
                    _StatBox(label: 'MVP', value: '${player.mvpCount}',
                        color: AppTheme.accentGold,
                        emoji: '👑'),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Grafico voti nel tempo ────────────────────────
                if (votePoints.length >= 2) ...[
                  const FifaSectionHeader('Andamento Voti',
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
                              interval: (votePoints.length / 5).ceilToDouble().clamp(1, 99),
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
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: votePoints,
                            isCurved: true,
                            color: AppTheme.accentGold,
                            barWidth: 2.5,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, _, __, ___) =>
                                  FlDotCirclePainter(
                                radius: 4,
                                color: AppTheme.accentGold,
                                strokeWidth: 1.5,
                                strokeColor: AppTheme.bg,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.accentGold.withOpacity(0.08),
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
                              color: AppTheme.accentGold.withOpacity(0.35),
                              barWidth: 1,
                              dashArray: [6, 4],
                              dotData: const FlDotData(show: false),
                            ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots.map((s) {
                              if (s.barIndex == 1) return null; // nascondi tooltip media
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
                      color: AppTheme.accentGold.withOpacity(0.5),
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Grafico gol per partita ───────────────────────
                if (totalGoals > 0) ...[
                  const FifaSectionHeader('Gol per Partita',
                      accent: AppTheme.accentRed),
                  _ChartCard(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (goalPoints.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1),
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
                                if (v != v.floorToDouble()) return const SizedBox();
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
                                if (i < 0 || i >= dateLabels.length) return const SizedBox();
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
                                toY: spot.y == 0 ? 0.05 : spot.y, // piccolo segno anche per 0
                                color: hasGoal
                                    ? AppTheme.accentRed
                                    : AppTheme.border,
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
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Grafico vittorie/pareggi/sconfitte ───────────
                if (totalGames > 0) ...[
                  const FifaSectionHeader('Risultati',
                      accent: AppTheme.accentBlue),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        // Grafico torta
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 32,
                              sections: [
                                if (wins > 0)
                                  PieChartSectionData(
                                    value: wins.toDouble(),
                                    color: AppTheme.accentGreen,
                                    radius: 28,
                                    title: '',
                                  ),
                                if (draws > 0)
                                  PieChartSectionData(
                                    value: draws.toDouble(),
                                    color: AppTheme.accentGold,
                                    radius: 28,
                                    title: '',
                                  ),
                                if (losses > 0)
                                  PieChartSectionData(
                                    value: losses.toDouble(),
                                    color: AppTheme.accentRed,
                                    radius: 28,
                                    title: '',
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Legenda
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _LegendRow(
                                color: AppTheme.accentGreen,
                                label: 'Vittorie',
                                count: wins,
                                total: totalGames,
                              ),
                              const SizedBox(height: 10),
                              _LegendRow(
                                color: AppTheme.accentGold,
                                label: 'Pareggi',
                                count: draws,
                                total: totalGames,
                              ),
                              const SizedBox(height: 10),
                              _LegendRow(
                                color: AppTheme.accentRed,
                                label: 'Sconfitte',
                                count: losses,
                                total: totalGames,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Grafico partite per mese ──────────────────────
                if (sortedMonthKeys.length >= 2) ...[
                  const FifaSectionHeader('Partite per Mese',
                      accent: AppTheme.accentBlue),
                  _ChartCard(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (matchesByMonth.values.reduce((a, b) => a > b ? a : b) + 1).toDouble(),
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
                                if (v != v.floorToDouble()) return const SizedBox();
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
                                if (i < 0 || i >= sortedMonthKeys.length) return const SizedBox();
                                final step = (sortedMonthKeys.length / 5).ceil().clamp(1, 99);
                                if (i % step != 0) return const SizedBox();
                                // "yyyy-MM" -> "mmm yy"
                                final parts = sortedMonthKeys[i].split('-');
                                final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                                return Text(
                                  DateFormat('MMM yy', 'it_IT').format(dt),
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
                              final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                              final label = DateFormat('MMMM yyyy', 'it_IT').format(dt);
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
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Messaggio se non ci sono abbastanza dati ──────
                if (votePoints.length < 2 && totalGoals == 0)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Center(
                      child: Text(
                        'Servono almeno 2 partite con voti per mostrare i grafici.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widget locali
// ─────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String? emoji;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 1),
              ],
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: emoji != null ? 18 : 22,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              FifaLabel(label, color: color.withOpacity(0.6), fontSize: 8),
            ],
          ),
        ),
      );
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;
  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '$count ($pct%)',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        height: 200,
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: child,
      );
}
