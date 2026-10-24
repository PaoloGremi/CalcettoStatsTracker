part of '../player_stats_screen.dart';

/// Record: traguardi in carriera.
class _RecordsTab extends StatelessWidget {
  final PlayerModel player;
  final PlayerStatsSummary summary;

  const _RecordsTab({required this.player, required this.summary});

  @override
  Widget build(BuildContext context) {
    final matches = summary.matches;
    final totalGames = summary.totalGames;

    final sections = <Widget>[
      if (totalGames > 0)
        ..._section('Serie Record', AppTheme.accentGold,
            _RecordStreaksCard(summary: summary)),
      if (summary.bestVoteMatch != null || summary.mostGoalsMatch != null)
        ..._section('Miglior Partita', AppTheme.accentGreen,
            _BestMatchesCard(summary: summary)),
      // ── Timeline Traguardi ────────────────────────────
      if (totalGames > 0)
        ..._section(
            'Traguardi in Carriera',
            AppTheme.accentGold,
            _MilestonesCard(
              matches: matches,
              playerId: player.id,
              mvpCount: player.mvpCount,
              bestGoalCount: player.bestGoalCount,
              hustleCount: player.hustleCount,
            )),
    ];
    if (sections.isEmpty) return const _EmptyTab();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: sections,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Timeline Traguardi in Carriera
// ─────────────────────────────────────────────────────────────

class _MilestonesCard extends StatelessWidget {
  final List<MatchModel> matches;
  final String playerId;
  final int mvpCount;
  final int bestGoalCount;
  final int hustleCount;

  const _MilestonesCard({
    required this.matches,
    required this.playerId,
    required this.mvpCount,
    required this.bestGoalCount,
    required this.hustleCount,
  });

  @override
  Widget build(BuildContext context) {
    final milestones = <({
      DateTime date,
      String title,
      String subtitle,
      Color color,
      String icon
    })>[];

    // ── Prima partita ────────────────────────────────────────
    if (matches.isNotEmpty) {
      milestones.add((
        date: matches.first.date,
        title: 'Prima partita',
        subtitle: formatDayMonthYear(matches.first.date),
        color: AppTheme.accentBlue,
        icon: '🎮',
      ));
    }

    // ── Traguardi partite: 10, 25, 50, 100 ──────────────────
    const gamesMilestones = [10, 25, 50, 100];
    for (final target in gamesMilestones) {
      if (matches.length >= target) {
        final m = matches[target - 1];
        milestones.add((
          date: m.date,
          title: '$target partite giocate',
          subtitle: formatDayMonthYear(m.date),
          color: AppTheme.accentBlue,
          icon: target >= 50 ? '🏟️' : '⚽',
        ));
      }
    }

    // ── Primo gol ────────────────────────────────────────────
    int cumGoals = 0;
    const goalMilestones = [1, 5, 10, 25, 50];
    int nextGoalIdx = 0;
    for (final m in matches) {
      cumGoals += (m.goals[playerId] ?? 0);
      while (nextGoalIdx < goalMilestones.length &&
          cumGoals >= goalMilestones[nextGoalIdx]) {
        final target = goalMilestones[nextGoalIdx];
        milestones.add((
          date: m.date,
          title: target == 1 ? 'Primo gol ⚽' : '$target gol in carriera',
          subtitle: formatDayMonthYear(m.date),
          color: AppTheme.accentRed,
          icon: target == 1 ? '🥅' : '🔥',
        ));
        nextGoalIdx++;
      }
    }

    // ── Miglior voto ─────────────────────────────────────────
    double bestVote = 0;
    DateTime? bestVoteDate;
    for (final m in matches) {
      final v = m.votes[playerId];
      if (v != null && v > bestVote) {
        bestVote = v;
        bestVoteDate = m.date;
      }
    }
    if (bestVoteDate != null && bestVote >= 8) {
      milestones.add((
        date: bestVoteDate,
        title: 'Voto record — ${bestVote.toStringAsFixed(1)}',
        subtitle: formatDayMonthYear(bestVoteDate),
        color: AppTheme.accentGold,
        icon: '⭐',
      ));
    }

    // Ordina per data
    milestones.sort((a, b) => a.date.compareTo(b.date));

    // ── Premi (senza data precisa) ───────────────────────────
    final prizes =
        <({String title, String subtitle, Color color, String icon})>[];
    if (mvpCount > 0) {
      prizes.add((
        title: 'MVP',
        subtitle: '$mvpCount ${mvpCount == 1 ? 'volta' : 'volte'}',
        color: AppTheme.accentGold,
        icon: '🏆',
      ));
    }
    if (bestGoalCount > 0) {
      prizes.add((
        title: 'Best Goal',
        subtitle: '$bestGoalCount ${bestGoalCount == 1 ? 'volta' : 'volte'}',
        color: AppTheme.accentGreen,
        icon: '🎯',
      ));
    }
    if (hustleCount > 0) {
      prizes.add((
        title: 'Combattivo',
        subtitle: '$hustleCount ${hustleCount == 1 ? 'volta' : 'volte'}',
        color: AppTheme.accentOrange,
        icon: '💪',
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Timeline ─────────────────────────────────────────
        if (milestones.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: milestones.asMap().entries.map((entry) {
                final i = entry.key;
                final ms = entry.value;
                final isLast = i == milestones.length - 1;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icona + linea verticale
                      SizedBox(
                        width: 32,
                        child: Column(
                          children: [
                            Text(ms.icon, style: const TextStyle(fontSize: 16)),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 1.5,
                                  color: AppTheme.border,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Testo
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ms.title,
                                style: TextStyle(
                                  color: ms.color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ms.subtitle,
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

        // ── Sezione Premi ─────────────────────────────────────
        if (prizes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: FifaLabel('PREMI', color: AppTheme.textMuted, fontSize: 10),
          ),
          Row(
            children: prizes.map((p) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.color.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    children: [
                      Text(p.icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        p.subtitle,
                        style: TextStyle(
                          color: p.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FifaLabel(p.title,
                          color: p.color.withValues(alpha: 0.7), fontSize: 9),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
