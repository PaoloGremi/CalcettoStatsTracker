part of '../player_stats_screen.dart';

/// Le due partite migliori: per voto e per gol. Tappabili.
class _BestMatchesCard extends StatelessWidget {
  final PlayerStatsSummary summary;

  const _BestMatchesCard({required this.summary});

  Widget _card(BuildContext context, String label, MatchModel? m, Color color) {
    if (m == null) return const Expanded(child: SizedBox.shrink());
    final field = Provider.of<DataService>(context, listen: false)
        .getFieldById(m.fieldLocation);
    final fieldName = field?.name ?? m.fieldLocation;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MatchDetailScreen(match: m)),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              FifaLabel(label, color: color, fontSize: 10),
              const SizedBox(height: 6),
              Text(
                '${summary.goalsForOf(m)} - ${summary.goalsAgainstOf(m)}',
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(formatShortDate(m.date),
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 11)),
              if (fieldName.isNotEmpty)
                Text(fieldName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(context, 'VOTO PIÙ ALTO', summary.bestVoteMatch,
            AppTheme.accentGold),
        const SizedBox(width: 10),
        _card(context, 'PIÙ GOL', summary.mostGoalsMatch, AppTheme.accentRed),
      ],
    );
  }
}
