part of '../player_stats_screen.dart';

/// Risultati: V/P/S, win-rate rolling, statistiche per campo.
class _ResultsTab extends StatelessWidget {
  final PlayerModel player;
  final PlayerStatsSummary summary;

  const _ResultsTab({required this.player, required this.summary});

  @override
  Widget build(BuildContext context) {
    final dateLabels =
        summary.matches.map((m) => formatShortDate(m.date)).toList();
    final matches = summary.matches;
    final totalGames = summary.totalGames;
    final wins = summary.wins;
    final draws = summary.draws;
    final losses = summary.losses;
    final winRatePoints = summary.rollingWinRate
        .map((p) => FlSpot(p.matchIndex.toDouble(), p.pct))
        .toList();

    final sections = <Widget>[
      // ── Grafico vittorie/pareggi/sconfitte ───────────
      if (totalGames > 0)
        ..._section(
            'Risultati',
            AppTheme.accentBlue,
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
            )),

      // ── Win-Rate Rolling ──────────────────────────────
      if (winRatePoints.length >= 2) ...[
        const FifaSectionHeader('Win-Rate (rolling 5 partite)',
            accent: AppTheme.accentGreen),
        _ChartCard(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (v) {
                  if (v == 50) {
                    return FlLine(
                        color: AppTheme.accentGold.withValues(alpha: 0.5),
                        strokeWidth: 1,
                        dashArray: [4, 4]);
                  }
                  return FlLine(color: AppTheme.border, strokeWidth: 1);
                },
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 25,
                    reservedSize: 34,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}%',
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
                      if (i < 0 || i >= winRatePoints.length) {
                        return const SizedBox();
                      }
                      final step =
                          (winRatePoints.length / 5).ceil().clamp(1, 99);
                      // allinea all'indice originale
                      final origIdx = i - (PlayerStatsSummary.movingWindow - 1);
                      if (origIdx < 0 || origIdx % step != 0) {
                        return const SizedBox();
                      }
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
                LineChartBarData(
                  spots: winRatePoints,
                  isCurved: true,
                  color: AppTheme.accentGreen,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.accentGreen.withValues(alpha: 0.2),
                        AppTheme.accentGreen.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final i = s.x.toInt();
                    final date = i < dateLabels.length ? dateLabels[i] : '';
                    return LineTooltipItem(
                      '$date\n${s.y.toStringAsFixed(0)}% vittorie',
                      const TextStyle(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 12),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 1.5,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 6),
              const Text('50% (pareggio tendenziale)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
        ),
      ],

      // ── Statistiche per Campo ─────────────────────────────
      if (totalGames > 0)
        ..._section('Statistiche per Campo', AppTheme.accentGreen,
            _FieldStatsCard(matches: matches, playerId: player.id)),
    ];
    if (sections.isEmpty) return const _EmptyTab();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: sections,
    );
  }
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
    final data = Provider.of<DataService>(context, listen: false);
    // Aggrega dati per campo
    final fieldData = <String, _FieldStat>{};
    for (final m in matches) {
      final field = data.getFieldById(m.fieldLocation);
      final loc = field?.name ??
          (m.fieldLocation.isEmpty ? 'Sconosciuto' : m.fieldLocation);
      final imagePath = field?.imagePath;

      fieldData.putIfAbsent(loc, () => _FieldStat(imagePath: imagePath));
      final stat = fieldData[loc]!;
      stat.games++;

      final inTeamA = m.teamA.contains(playerId);
      final ps = inTeamA ? m.scoreA : m.scoreB;
      final os = inTeamA ? m.scoreB : m.scoreA;
      if (ps > os) {
        stat.wins++;
      } else if (ps == os) {
        stat.draws++;
      } else {
        stat.losses++;
      }

      final vote = m.votes[playerId];
      if (vote != null) {
        stat.totalVotes += vote;
        stat.votesCount++;
      }
      stat.goals += m.goals[playerId] ?? 0;
    }

    final sorted = fieldData.entries.toList()
      ..sort((a, b) => b.value.games.compareTo(a.value.games));

    return Column(
      children: sorted.map((entry) {
        final loc = entry.key;
        final stat = entry.value;
        final avg =
            stat.votesCount > 0 ? stat.totalVotes / stat.votesCount : null;
        final hasImage =
            stat.imagePath != null && File(stat.imagePath!).existsSync();

        final winsColor = stat.wins > stat.losses
            ? AppTheme.accentGreen
            : stat.losses > stat.wins
                ? AppTheme.accentRed
                : AppTheme.accentGold;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 130,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Sfondo immagine campo ──────────────────────────
              if (hasImage)
                Image.file(
                  File(stat.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),

              // ── Overlay scuro (sempre, più intenso senza immagine) ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: hasImage
                        ? [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.black.withValues(alpha: 0.72),
                          ]
                        : [
                            AppTheme.surface,
                            AppTheme.surface,
                          ],
                  ),
                ),
              ),

              // ── Contenuto ─────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nome campo + partite
                    Row(
                      children: [
                        const Text('🏟️', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc,
                            style: TextStyle(
                              color: hasImage
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: hasImage
                                  ? [
                                      const Shadow(
                                          blurRadius: 4, color: Colors.black54)
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black
                                .withValues(alpha: hasImage ? 0.35 : 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${stat.games} ${stat.games == 1 ? 'partita' : 'partite'}',
                            style: TextStyle(
                              color: hasImage
                                  ? Colors.white70
                                  : AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Metriche
                    Row(
                      children: [
                        _FieldMetric(
                          label: 'V/P/S',
                          value: '${stat.wins}/${stat.draws}/${stat.losses}',
                          color: hasImage ? Colors.white : winsColor,
                          valueColor: hasImage ? winsColor : null,
                          hasImage: hasImage,
                        ),
                        const SizedBox(width: 20),
                        _FieldMetric(
                          label: 'Voto medio',
                          value: avg != null ? avg.toStringAsFixed(1) : '—',
                          color: hasImage
                              ? Colors.white
                              : avg == null
                                  ? AppTheme.textMuted
                                  : avg >= 7.0
                                      ? AppTheme.accentGreen
                                      : avg >= 5.5
                                          ? AppTheme.accentGold
                                          : AppTheme.accentRed,
                          hasImage: hasImage,
                        ),
                        const SizedBox(width: 20),
                        _FieldMetric(
                          label: 'Gol',
                          value: '${stat.goals}',
                          color: hasImage
                              ? Colors.white
                              : stat.goals > 0
                                  ? AppTheme.accentRed
                                  : AppTheme.textMuted,
                          hasImage: hasImage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FieldStat {
  final String? imagePath; // ← aggiunto
  int games = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  double totalVotes = 0;
  int votesCount = 0;
  int goals = 0;

  _FieldStat({this.imagePath}); // ← aggiunto
}

class _FieldMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color? valueColor; // ← opzionale: colore separato per il valore
  final bool hasImage; // ← per aggiungere shadow

  const _FieldMetric({
    required this.label,
    required this.value,
    required this.color,
    this.valueColor,
    this.hasImage = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              shadows: hasImage
                  ? [const Shadow(blurRadius: 4, color: Colors.black87)]
                  : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: hasImage ? Colors.white60 : AppTheme.textMuted,
              fontSize: 10,
              shadows: hasImage
                  ? [const Shadow(blurRadius: 3, color: Colors.black54)]
                  : null,
            ),
          ),
        ],
      );
}
