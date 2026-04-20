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
        .where(
            (m) => m.teamA.contains(player.id) || m.teamB.contains(player.id))
        .toList();
    matches.sort((a, b) => a.date.compareTo(b.date));
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    final matches = _playerMatches();

    // Totale partite registrate nel sistema (non solo quelle del giocatore)
    final totalRegisteredMatches = HiveBoxes.matchesBox.length;

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
    final totalGoals = goalPoints.isEmpty
        ? 0
        : goalPoints.map((s) => s.y.toInt()).reduce((a, b) => a + b);

    // ── Vittorie / Pareggi / Sconfitte ───────────────────────
    int wins = 0, draws = 0, losses = 0;
    for (final m in matches) {
      final inTeamA = m.teamA.contains(player.id);
      final playerScore = inTeamA ? m.scoreA : m.scoreB;
      final oppScore = inTeamA ? m.scoreB : m.scoreA;
      if (playerScore > oppScore)
        wins++;
      else if (playerScore == oppScore)
        draws++;
      else
        losses++;
    }

    // ── Statistiche aggiuntive ────────────────────────────────
    // Media gol a partita
    final avgGoals = totalGames > 0 ? totalGoals / totalGames : 0.0;

    // % partecipazione (partite giocate dal giocatore / tutte le partite registrate)
    final participationPct = totalRegisteredMatches > 0
        ? (totalGames / totalRegisteredMatches * 100).round()
        : 0;

    // Striscia corrente (ultima serie consecutiva V/P/S)
    String currentStreak = '—';
    if (matches.isNotEmpty) {
      final lastResult = () {
        final m = matches.last;
        final inTeamA = m.teamA.contains(player.id);
        final ps = inTeamA ? m.scoreA : m.scoreB;
        final os = inTeamA ? m.scoreB : m.scoreA;
        if (ps > os) return 'V';
        if (ps == os) return 'P';
        return 'S';
      }();
      int streakCount = 0;
      for (int i = matches.length - 1; i >= 0; i--) {
        final m = matches[i];
        final inTeamA = m.teamA.contains(player.id);
        final ps = inTeamA ? m.scoreA : m.scoreB;
        final os = inTeamA ? m.scoreB : m.scoreA;
        final r = ps > os ? 'V' : (ps == os ? 'P' : 'S');
        if (r == lastResult)
          streakCount++;
        else
          break;
      }
      currentStreak = '$streakCount$lastResult';
    }

    // Partite consecutive senza sconfitta (striscia migliore)
    int bestUnbeaten = 0, currentUnbeaten = 0;
    for (final m in matches) {
      final inTeamA = m.teamA.contains(player.id);
      final ps = inTeamA ? m.scoreA : m.scoreB;
      final os = inTeamA ? m.scoreB : m.scoreA;
      if (ps >= os) {
        currentUnbeaten++;
        if (currentUnbeaten > bestUnbeaten) bestUnbeaten = currentUnbeaten;
      } else {
        currentUnbeaten = 0;
      }
    }

    // Partite con almeno un gol segnato
    final gamesWithGoal = goalPoints.where((s) => s.y > 0).length;

    // Voto più frequente (moda)
    final voteFreq = <double, int>{};
    for (final s in votePoints) {
      voteFreq[s.y] = (voteFreq[s.y] ?? 0) + 1;
    }
    double? modeVote;
    if (voteFreq.isNotEmpty) {
      modeVote =
          voteFreq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    // ── Partite per mese ─────────────────────────────────────
    // Mappa "yyyy-MM" -> conteggio partite
    final matchesByMonth = <String, int>{};
    for (final m in matches) {
      final key = DateFormat('yyyy-MM').format(m.date);
      matchesByMonth[key] = (matchesByMonth[key] ?? 0) + 1;
    }
    final sortedMonthKeys = matchesByMonth.keys.toList()..sort();

    // ── Distribuzione voti (istogramma) ──────────────────────
    // Raggruppa i voti in bucket: 1-2, 3-4, 5-6, 7-8, 9-10
    final voteDistribution = <String, int>{
      '1-2': 0,
      '3-4': 0,
      '5-6': 0,
      '7-8': 0,
      '9-10': 0,
    };
    for (final s in votePoints) {
      final v = s.y;
      if (v <= 2)
        voteDistribution['1-2'] = voteDistribution['1-2']! + 1;
      else if (v <= 4)
        voteDistribution['3-4'] = voteDistribution['3-4']! + 1;
      else if (v <= 6)
        voteDistribution['5-6'] = voteDistribution['5-6']! + 1;
      else if (v <= 8)
        voteDistribution['7-8'] = voteDistribution['7-8']! + 1;
      else
        voteDistribution['9-10'] = voteDistribution['9-10']! + 1;
    }

    // ── Voto medio per mese ───────────────────────────────────
    final votesByMonth = <String, List<double>>{};
    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final vote = m.votes[player.id];
      if (vote != null) {
        final key = DateFormat('yyyy-MM').format(m.date);
        votesByMonth.putIfAbsent(key, () => []).add(vote);
      }
    }
    final avgVoteByMonth = <String, double>{};
    for (final entry in votesByMonth.entries) {
      avgVoteByMonth[entry.key] =
          entry.value.reduce((a, b) => a + b) / entry.value.length;
    }
    final sortedVoteMonthKeys = avgVoteByMonth.keys.toList()..sort();

    // ── Gol cumulativi nel tempo ──────────────────────────────
    final cumulativeGoalPoints = <FlSpot>[];
    int cumGoals = 0;
    for (int i = 0; i < matches.length; i++) {
      cumGoals += (matches[i].goals[player.id] ?? 0);
      cumulativeGoalPoints.add(FlSpot(i.toDouble(), cumGoals.toDouble()));
    }

    // ── Voto medio per risultato (V/P/S) ─────────────────────
    final votesByResult = <String, List<double>>{'V': [], 'P': [], 'S': []};
    for (final m in matches) {
      final vote = m.votes[player.id];
      if (vote == null) continue;
      final inTeamA = m.teamA.contains(player.id);
      final ps = inTeamA ? m.scoreA : m.scoreB;
      final os = inTeamA ? m.scoreB : m.scoreA;
      if (ps > os)
        votesByResult['V']!.add(vote);
      else if (ps == os)
        votesByResult['P']!.add(vote);
      else
        votesByResult['S']!.add(vote);
    }
    double _avg(List<double> list) =>
        list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;
    final avgVoteWin = _avg(votesByResult['V']!);
    final avgVoteDraw = _avg(votesByResult['P']!);
    final avgVoteLoss = _avg(votesByResult['S']!);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title:
            FifaLabel(player.name, color: AppTheme.textPrimary, fontSize: 13),
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
                    _StatBox(
                        label: 'PARTITE',
                        value: '$totalGames',
                        color: AppTheme.accentBlue),
                    const SizedBox(width: 8),
                    _StatBox(
                        label: 'VOTO MEDIO',
                        value:
                            votedGames > 0 ? avgVote.toStringAsFixed(2) : '—',
                        color: AppTheme.accentGold),
                    const SizedBox(width: 8),
                    _StatBox(
                        label: 'GOL TOTALI',
                        value: '$totalGoals',
                        color: AppTheme.accentRed),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    _StatBox(
                        label: 'MIGLIOR VOTO',
                        value:
                            votedGames > 0 ? bestVote.toStringAsFixed(1) : '—',
                        color: AppTheme.accentGreen),
                    const SizedBox(width: 8),
                    _StatBox(
                        label: 'PEGGIOR VOTO',
                        value:
                            votedGames > 0 ? worstVote.toStringAsFixed(1) : '—',
                        color: AppTheme.accentOrange),
                    const SizedBox(width: 8),
                    _StatBox(
                        label: 'MVP',
                        value: '${player.mvpCount}',
                        color: AppTheme.accentGold,
                        emoji: '👑'),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Terza riga statistiche ────────────────────────
                Row(
                  children: [
                    _StatBox(
                      label: 'MEDIA GOL',
                      value: totalGames > 0 ? avgGoals.toStringAsFixed(2) : '—',
                      color: AppTheme.accentRed,
                      emoji: '⚽',
                    ),
                    const SizedBox(width: 8),
                    _StatBox(
                      label: 'PARTITE GOL',
                      value: '$gamesWithGoal',
                      color: AppTheme.accentOrange,
                      emoji: '🎯',
                    ),
                    const SizedBox(width: 8),
                    _StatBox(
                      label: 'PARTECIPAZ.',
                      value: '$participationPct%',
                      color: AppTheme.accentBlue,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Quarta riga statistiche ───────────────────────
                Row(
                  children: [
                    _StatBox(
                      label: 'STRISCIA',
                      value: currentStreak,
                      color: currentStreak.endsWith('V')
                          ? AppTheme.accentGreen
                          : currentStreak.endsWith('S')
                              ? AppTheme.accentRed
                              : AppTheme.accentGold,
                    ),
                    const SizedBox(width: 8),
                    _StatBox(
                      label: 'IMBATTUTO',
                      value: '$bestUnbeaten',
                      color: AppTheme.accentGreen,
                      emoji: '🛡️',
                    ),
                    const SizedBox(width: 8),
                    _StatBox(
                      label: 'VOTO MODALE',
                      value:
                          modeVote != null ? modeVote.toStringAsFixed(1) : '—',
                      color: AppTheme.accentGold,
                    ),
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
                              interval: (votePoints.length / 5)
                                  .ceilToDouble()
                                  .clamp(1, 99),
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
                                FlSpot(
                                    (matches.length - 1).toDouble(), avgVote),
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
                              if (s.barIndex == 1)
                                return null; // nascondi tooltip media
                              final i = s.x.toInt();
                              final date =
                                  i < dateLabels.length ? dateLabels[i] : '';
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
                                if (v != v.floorToDouble())
                                  return const SizedBox();
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
                                if (i < 0 || i >= dateLabels.length)
                                  return const SizedBox();
                                // mostra solo ogni N label per non sovraffollare
                                final step =
                                    (matches.length / 5).ceil().clamp(1, 99);
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
                              final date =
                                  i < dateLabels.length ? dateLabels[i] : '';
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
                        maxY: (matchesByMonth.values
                                    .reduce((a, b) => a > b ? a : b) +
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
                                if (v != v.floorToDouble())
                                  return const SizedBox();
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
                                if (i < 0 || i >= sortedMonthKeys.length)
                                  return const SizedBox();
                                final step = (sortedMonthKeys.length / 5)
                                    .ceil()
                                    .clamp(1, 99);
                                if (i % step != 0) return const SizedBox();
                                // "yyyy-MM" -> "mmm yy"
                                final parts = sortedMonthKeys[i].split('-');
                                final dt = DateTime(
                                    int.parse(parts[0]), int.parse(parts[1]));
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
                              final dt = DateTime(
                                  int.parse(parts[0]), int.parse(parts[1]));
                              final label =
                                  DateFormat('MMMM yyyy', 'it_IT').format(dt);
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

                // ── Grafico: Distribuzione Voti ──────────────────
                if (votePoints.length >= 3) ...[
                  const FifaSectionHeader('Distribuzione Voti',
                      accent: AppTheme.accentGold),
                  _ChartCard(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (voteDistribution.values
                                    .reduce((a, b) => a > b ? a : b) +
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
                                if (v != v.floorToDouble())
                                  return const SizedBox();
                                return Text(v.toInt().toString(),
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 10));
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (v, _) {
                                final labels = [
                                  '1-2',
                                  '3-4',
                                  '5-6',
                                  '7-8',
                                  '9-10'
                                ];
                                final i = v.toInt();
                                if (i < 0 || i >= labels.length)
                                  return const SizedBox();
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
                              final labels = [
                                '1-2',
                                '3-4',
                                '5-6',
                                '7-8',
                                '9-10'
                              ];
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
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Grafico: Voto Medio per Mese ─────────────────
                if (sortedVoteMonthKeys.length >= 2) ...[
                  const FifaSectionHeader('Voto Medio per Mese',
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
                                if (i < 0 || i >= sortedVoteMonthKeys.length)
                                  return const SizedBox();
                                final step = (sortedVoteMonthKeys.length / 4)
                                    .ceil()
                                    .clamp(1, 99);
                                if (i % step != 0) return const SizedBox();
                                final parts = sortedVoteMonthKeys[i].split('-');
                                final dt = DateTime(
                                    int.parse(parts[0]), int.parse(parts[1]));
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
                              getDotPainter: (_, __, ___, ____) =>
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
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots.map((s) {
                              final i = s.x.toInt();
                              if (i < 0 || i >= sortedVoteMonthKeys.length)
                                return null;
                              final parts = sortedVoteMonthKeys[i].split('-');
                              final dt = DateTime(
                                  int.parse(parts[0]), int.parse(parts[1]));
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
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Grafico: Gol Cumulativi nel Tempo ────────────
                if (totalGoals > 0 && cumulativeGoalPoints.length >= 2) ...[
                  const FifaSectionHeader('Gol Cumulativi',
                      accent: AppTheme.accentRed),
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
                                if (v != v.floorToDouble())
                                  return const SizedBox();
                                return Text(v.toInt().toString(),
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 10));
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= dateLabels.length)
                                  return const SizedBox();
                                final step =
                                    (matches.length / 5).ceil().clamp(1, 99);
                                if (i % step != 0) return const SizedBox();
                                return Text(dateLabels[i],
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
                        lineBarsData: [
                          LineChartBarData(
                            spots: cumulativeGoalPoints,
                            isCurved: false,
                            color: AppTheme.accentRed,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.accentRed.withOpacity(0.1),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots.map((s) {
                              final i = s.x.toInt();
                              final date =
                                  i < dateLabels.length ? dateLabels[i] : '';
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
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Grafico: Voto Medio per Risultato ────────────
                if (votePoints.isNotEmpty &&
                    (votesByResult['V']!.isNotEmpty ||
                        votesByResult['S']!.isNotEmpty)) ...[
                  const FifaSectionHeader('Voto per Risultato',
                      accent: AppTheme.accentBlue),
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
                                getDrawingHorizontalLine: (_) => FlLine(
                                    color: AppTheme.border, strokeWidth: 1),
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
                                          color: AppTheme.textMuted,
                                          fontSize: 10),
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
                                      if (i < 0 || i >= labels.length)
                                        return const SizedBox();
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
                                count: votesByResult['V']!.length),
                            _ResultAvgBadge(
                                label: 'Pareggi',
                                avg: avgVoteDraw,
                                color: AppTheme.accentGold,
                                count: votesByResult['P']!.length),
                            _ResultAvgBadge(
                                label: 'Sconfitte',
                                avg: avgVoteLoss,
                                color: AppTheme.accentRed,
                                count: votesByResult['S']!.length),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Radar Performance ─────────────────────────────────
                if (totalGames > 0) ...[
                  const FifaSectionHeader('Radar Performance',
                      accent: AppTheme.accentBlue),
                  _RadarCard(
                    avgVote: avgVote,
                    totalGoals: totalGoals,
                    totalGames: totalGames,
                    mvpCount: player.mvpCount,
                    hustleCount: player.hustleCount,
                    bestGoalCount: player.bestGoalCount,
                  ),
                  const SizedBox(height: 24),
                ],

// ── Statistiche per Campo ─────────────────────────────
                if (totalGames > 0) ...[
                  const FifaSectionHeader('Statistiche per Campo',
                      accent: AppTheme.accentGreen),
                  _FieldStatsCard(matches: matches, playerId: player.id),
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
          width: 10,
          height: 10,
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

class _ResultAvgBadge extends StatelessWidget {
  final String label;
  final double avg;
  final Color color;
  final int count;

  const _ResultAvgBadge({
    required this.label,
    required this.avg,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            avg > 0 ? avg.toStringAsFixed(1) : '—',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          FifaLabel(label, color: color.withOpacity(0.7), fontSize: 8),
          const SizedBox(height: 1),
          FifaLabel('($count partite)', color: AppTheme.textMuted, fontSize: 8),
        ],
      );
}
// ─────────────────────────────────────────────────────────────
// Radar Performance
// ─────────────────────────────────────────────────────────────

class _RadarCard extends StatelessWidget {
  final double avgVote;
  final int totalGoals;
  final int totalGames;
  final int mvpCount;
  final int hustleCount;
  final int bestGoalCount;

  const _RadarCard({
    required this.avgVote,
    required this.totalGoals,
    required this.totalGames,
    required this.mvpCount,
    required this.hustleCount,
    required this.bestGoalCount,
  });

  // Normalizza un valore su scala 0–1 con un cap "realistico"
  double _norm(double value, double max) => (value / max).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    // Scala di riferimento per normalizzazione (adatta a poche partite)
    final votoNorm = _norm(avgVote, 10.0);
    final golNorm =
        _norm(totalGoals / totalGames, 2.0); // media gol/partita, cap 2
    final mvpNorm = _norm(mvpCount.toDouble(), 5.0);
    final hustleNorm = _norm(hustleCount.toDouble(), 5.0);
    final bestGolNorm = _norm(bestGoalCount.toDouble(), 5.0);

    const labels = ['Voto', 'Gol', 'MVP', 'Combatt.', 'Best ⚽'];
    final values = [votoNorm, golNorm, mvpNorm, hustleNorm, bestGolNorm];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle:
                    const TextStyle(color: Colors.transparent, fontSize: 0),
                radarBorderData:
                    const BorderSide(color: AppTheme.border, width: 1),
                gridBorderData:
                    const BorderSide(color: AppTheme.border, width: 1),
                tickBorderData: BorderSide(
                    color: AppTheme.border.withOpacity(0.4), width: 1),
                titleTextStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                getTitle: (index, angle) =>
                    RadarChartTitle(text: labels[index]),
                dataSets: [
                  RadarDataSet(
                    fillColor: AppTheme.accentBlue.withOpacity(0.18),
                    borderColor: AppTheme.accentBlue,
                    borderWidth: 2,
                    entryRadius: 4,
                    dataEntries:
                        values.map((v) => RadarEntry(value: v)).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legenda valori reali
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _RadarLegendItem(
                  label: 'Voto medio',
                  value: avgVote.toStringAsFixed(1),
                  color: AppTheme.accentBlue),
              _RadarLegendItem(
                  label: 'Media gol/partita',
                  value: (totalGoals / totalGames).toStringAsFixed(2),
                  color: AppTheme.accentBlue),
              _RadarLegendItem(
                  label: 'MVP', value: '$mvpCount', color: AppTheme.accentBlue),
              _RadarLegendItem(
                  label: 'Combattivo',
                  value: '$hustleCount',
                  color: AppTheme.accentBlue),
              _RadarLegendItem(
                  label: 'Best ⚽',
                  value: '$bestGoalCount',
                  color: AppTheme.accentBlue),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadarLegendItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RadarLegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────
// Statistiche per Campo
// ─────────────────────────────────────────────────────────────

class _FieldStatsCard extends StatelessWidget {
  final List<MatchModel> matches;
  final String playerId;

  const _FieldStatsCard({required this.matches, required this.playerId});

  @override
  Widget build(BuildContext context) {
    // Aggrega dati per campo
    final fieldData = <String, _FieldStat>{};
    for (final m in matches) {
      // ✅ Dopo — risolve il nome dal box dei campi
      final field = HiveBoxes.fieldsBox.get(m.fieldLocation);
      final loc = field?.name ??
          (m.fieldLocation.isEmpty ? 'Sconosciuto' : m.fieldLocation);
      fieldData.putIfAbsent(loc, () => _FieldStat());
      final stat = fieldData[loc]!;
      stat.games++;

      final inTeamA = m.teamA.contains(playerId);
      final ps = inTeamA ? m.scoreA : m.scoreB;
      final os = inTeamA ? m.scoreB : m.scoreA;
      if (ps > os)
        stat.wins++;
      else if (ps == os)
        stat.draws++;
      else
        stat.losses++;

      final vote = m.votes[playerId];
      if (vote != null) {
        stat.totalVotes += vote;
        stat.votesCount++;
      }
      stat.goals += m.goals[playerId] ?? 0;
    }

    // Ordina per numero partite decrescente
    final sorted = fieldData.entries.toList()
      ..sort((a, b) => b.value.games.compareTo(a.value.games));

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final loc = entry.value.key;
          final stat = entry.value.value;
          final avg =
              stat.votesCount > 0 ? stat.totalVotes / stat.votesCount : null;
          final isLast = i == sorted.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome campo + partite
                Row(
                  children: [
                    const Text('🏟️', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      '${stat.games} ${stat.games == 1 ? 'partita' : 'partite'}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Metriche in riga
                Row(
                  children: [
                    _FieldMetric(
                      label: 'V/P/S',
                      value: '${stat.wins}/${stat.draws}/${stat.losses}',
                      color: stat.wins > stat.losses
                          ? AppTheme.accentGreen
                          : stat.losses > stat.wins
                              ? AppTheme.accentRed
                              : AppTheme.accentGold,
                    ),
                    const SizedBox(width: 12),
                    _FieldMetric(
                      label: 'Voto medio',
                      value: avg != null ? avg.toStringAsFixed(1) : '—',
                      color: avg == null
                          ? AppTheme.textMuted
                          : avg >= 7.0
                              ? AppTheme.accentGreen
                              : avg >= 5.5
                                  ? AppTheme.accentGold
                                  : AppTheme.accentRed,
                    ),
                    const SizedBox(width: 12),
                    _FieldMetric(
                      label: 'Gol',
                      value: '${stat.goals}',
                      color: stat.goals > 0
                          ? AppTheme.accentRed
                          : AppTheme.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FieldStat {
  int games = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  double totalVotes = 0;
  int votesCount = 0;
  int goals = 0;
}

class _FieldMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FieldMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      );
}
