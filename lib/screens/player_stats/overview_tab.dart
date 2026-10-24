part of '../player_stats_screen.dart';

/// Panoramica: riquadri riassuntivi, radar e form recente.
/// Ha sempre almeno i riquadri, quindi non mostra mai `_EmptyTab`.
class _OverviewTab extends StatelessWidget {
  final PlayerModel player;
  final PlayerStatsSummary summary;

  const _OverviewTab({required this.player, required this.summary});

  @override
  Widget build(BuildContext context) {
    final totalGames = summary.totalGames;
    final votedGames = summary.votedGames;
    final avgVote = summary.avgVote;
    final bestVote = summary.bestVote;
    final worstVote = summary.worstVote;
    final totalGoals = summary.totalGoals;
    final avgGoals = summary.avgGoals;
    final gamesWithGoal = summary.gamesWithGoal;
    final participationPct = summary.participationPct;
    final currentStreak = summary.currentStreak;
    final bestUnbeaten = summary.bestUnbeaten;
    final modeVote = summary.modeVote;
    final recentResults = summary.recentResults;

    final sections = <Widget>[
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
              value: votedGames > 0 ? avgVote.toStringAsFixed(2) : '—',
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
              value: votedGames > 0 ? bestVote.toStringAsFixed(1) : '—',
              color: AppTheme.accentGreen),
          const SizedBox(width: 8),
          _StatBox(
              label: 'PEGGIOR VOTO',
              value: votedGames > 0 ? worstVote.toStringAsFixed(1) : '—',
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
            value: modeVote != null ? modeVote.toStringAsFixed(1) : '—',
            color: AppTheme.accentGold,
          ),
        ],
      ),

      const SizedBox(height: 24),

      // ── Radar Performance ─────────────────────────────────
      if (totalGames > 0)
        ..._section(
            'Radar Performance',
            AppTheme.accentBlue,
            _RadarCard(
              avgVote: avgVote,
              totalGoals: totalGoals,
              totalGames: totalGames,
              mvpCount: player.mvpCount,
              hustleCount: player.hustleCount,
              bestGoalCount: player.bestGoalCount,
              fifaStats: PlayerStatsCalculator.compute(player.id),
            )),

      // ── Form Recente (ultime 10 partite) ─────────────
      if (recentResults.length >= 3)
        ..._section(
            'Form Recente',
            AppTheme.accentGreen,
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: recentResults.map((r) {
                      final color = r.outcome == MatchOutcome.win
                          ? AppTheme.accentGreen
                          : r.outcome == MatchOutcome.draw
                              ? AppTheme.accentGold
                              : AppTheme.accentRed;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            children: [
                              // Voto sopra
                              Text(
                                r.vote != null
                                    ? r.vote!.toStringAsFixed(0)
                                    : '—',
                                style: TextStyle(
                                  color: r.vote != null
                                      ? color
                                      : AppTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Badge risultato
                              Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: color.withValues(alpha: 0.4)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  r.outcome.label,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Data sotto
                              Text(
                                formatShortDate(r.date),
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Riepilogo forma
                  Builder(builder: (context) {
                    final recentWins = recentResults
                        .where((r) => r.outcome == MatchOutcome.win)
                        .length;
                    final recentDraws = recentResults
                        .where((r) => r.outcome == MatchOutcome.draw)
                        .length;
                    final recentLosses = recentResults
                        .where((r) => r.outcome == MatchOutcome.loss)
                        .length;
                    final recentVotes = recentResults
                        .where((r) => r.vote != null)
                        .map((r) => r.vote!)
                        .toList();
                    final recentAvgVote = recentVotes.isNotEmpty
                        ? recentVotes.reduce((a, b) => a + b) /
                            recentVotes.length
                        : 0.0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ConsistStat(
                            label: 'Vittorie',
                            value: '$recentWins',
                            color: AppTheme.accentGreen),
                        _ConsistStat(
                            label: 'Pareggi',
                            value: '$recentDraws',
                            color: AppTheme.accentGold),
                        _ConsistStat(
                            label: 'Sconfitte',
                            value: '$recentLosses',
                            color: AppTheme.accentRed),
                        _ConsistStat(
                            label: 'Voto medio',
                            value: recentAvgVote > 0
                                ? recentAvgVote.toStringAsFixed(1)
                                : '—',
                            color: AppTheme.accentBlue),
                      ],
                    );
                  }),
                ],
              ),
            )),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: sections,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Radar Performance
// ─────────────────────────────────────────────────────────────

class _RadarCard extends StatefulWidget {
  final double avgVote;
  final int totalGoals;
  final int totalGames;
  final int mvpCount;
  final int hustleCount;
  final int bestGoalCount;
  final ComputedFifaStats fifaStats;

  const _RadarCard({
    required this.avgVote,
    required this.totalGoals,
    required this.totalGames,
    required this.mvpCount,
    required this.hustleCount,
    required this.bestGoalCount,
    required this.fifaStats,
  });

  @override
  State<_RadarCard> createState() => _RadarCardState();
}

class _RadarCardState extends State<_RadarCard> {
  int _selectedTab = 0; // 0 = Performance, 1 = Attributi FIFA

  double _norm(double value, double max) => (value / max).clamp(0.0, 1.0);

  RadarDataSet _scaleAnchor(int count, double value) => RadarDataSet(
        fillColor: Colors.transparent,
        borderColor: Colors.transparent,
        borderWidth: 0,
        entryRadius: 0,
        dataEntries: List.filled(count, RadarEntry(value: value)),
      );

  @override
  Widget build(BuildContext context) {
    // ── Dati radar Performance ───────────────────────────────
    final votoNorm = _norm(widget.avgVote, 10.0);
    final golNorm = _norm(widget.totalGoals / widget.totalGames, 2.0);
    final mvpNorm = _norm(widget.mvpCount.toDouble(), 5.0);
    final hustleNorm = _norm(widget.hustleCount.toDouble(), 5.0);
    final bestGolNorm = _norm(widget.bestGoalCount.toDouble(), 5.0);

    const perfLabels = ['Voto', 'Gol', 'MVP', 'Combatt.', 'Best ⚽'];
    final perfValues = [votoNorm, golNorm, mvpNorm, hustleNorm, bestGolNorm];

    // ── Dati radar FIFA ──────────────────────────────────────
    final f = widget.fifaStats;
    final fifaLabels = ['VEL', 'TIR', 'PAS', 'DRI', 'DIF', 'FIS'];
    final fifaValues = [
      _norm(f.vel.toDouble(), 99.0),
      _norm(f.tir.toDouble(), 99.0),
      _norm(f.pas.toDouble(), 99.0),
      _norm(f.dri.toDouble(), 99.0),
      _norm(f.dif.toDouble(), 99.0),
      _norm(f.fis.toDouble(), 99.0),
    ];

    final isPerf = _selectedTab == 0;
    final labels = isPerf ? perfLabels : fifaLabels;
    final values = isPerf ? perfValues : fifaValues;
    final accentColor = isPerf ? AppTheme.accentBlue : AppTheme.accentGold;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // ── Tab selector ─────────────────────────────────
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                _TabButton(
                  label: 'Performance',
                  selected: _selectedTab == 0,
                  color: AppTheme.accentBlue,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                _TabButton(
                  label: 'Attributi FIFA',
                  selected: _selectedTab == 1,
                  color: AppTheme.accentGold,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Radar chart ──────────────────────────────────
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle:
                    const TextStyle(color: Colors.transparent, fontSize: 0),
                radarBorderData: BorderSide(color: AppTheme.border, width: 1),
                gridBorderData: BorderSide(color: AppTheme.border, width: 1),
                tickBorderData: BorderSide(
                    color: AppTheme.border.withValues(alpha: 0.4), width: 1),
                titleTextStyle: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                getTitle: (index, angle) =>
                    RadarChartTitle(text: labels[index]),
                dataSets: [
                  // fl_chart adatta la scala ai dati (bordo = valore più
                  // alto, primo anello = più basso). Due serie invisibili
                  // a 0 e 1 fissano la scala per tutti i giocatori.
                  _scaleAnchor(labels.length, 0),
                  _scaleAnchor(labels.length, 1),
                  RadarDataSet(
                    fillColor: accentColor.withValues(alpha: 0.18),
                    borderColor: accentColor,
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

          // ── Legenda valori reali ─────────────────────────
          if (isPerf) ...[
            Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _RadarLegendItem(
                    label: 'Voto medio',
                    value: widget.avgVote.toStringAsFixed(1),
                    color: AppTheme.accentBlue),
                _RadarLegendItem(
                    label: 'Media gol/partita',
                    value: (widget.totalGoals / widget.totalGames)
                        .toStringAsFixed(2),
                    color: AppTheme.accentBlue),
                _RadarLegendItem(
                    label: 'MVP',
                    value: '${widget.mvpCount}',
                    color: AppTheme.accentBlue),
                _RadarLegendItem(
                    label: 'Combattivo',
                    value: '${widget.hustleCount}',
                    color: AppTheme.accentBlue),
                _RadarLegendItem(
                    label: 'Best ⚽',
                    value: '${widget.bestGoalCount}',
                    color: AppTheme.accentBlue),
              ],
            ),
          ] else ...[
            Wrap(
              spacing: 16,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _RadarLegendItem(
                    label: 'VEL',
                    value: '${f.vel}',
                    color: AppTheme.accentGold),
                _RadarLegendItem(
                    label: 'TIR',
                    value: '${f.tir}',
                    color: AppTheme.accentGold),
                _RadarLegendItem(
                    label: 'PAS',
                    value: '${f.pas}',
                    color: AppTheme.accentGold),
                _RadarLegendItem(
                    label: 'DRI',
                    value: '${f.dri}',
                    color: AppTheme.accentGold),
                _RadarLegendItem(
                    label: 'DIF',
                    value: '${f.dif}',
                    color: AppTheme.accentGold),
                _RadarLegendItem(
                    label: 'FIS',
                    value: '${f.fis}',
                    color: AppTheme.accentGold),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color:
                  selected ? color.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: selected
                  ? Border.all(color: color.withValues(alpha: 0.5), width: 1)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? color : AppTheme.textMuted,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      );
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
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      );
}
