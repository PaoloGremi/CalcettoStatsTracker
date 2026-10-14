part of '../player_stats_screen.dart';

/// Mappa presenze stile calendario: una colonna per settimana, 7 celle per
/// giorno (lun→dom), colorate in base all'esito dell'ultima partita del giorno.
class _ActivityHeatmap extends StatefulWidget {
  final PlayerStatsSummary summary;
  final DateTime today;

  const _ActivityHeatmap({required this.summary, required this.today});

  @override
  State<_ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<_ActivityHeatmap> {
  static const double _cell = 12, _gap = 3;

  final _controller = ScrollController();
  late int _year;

  @override
  void initState() {
    super.initState();
    final years = widget.summary.activeYears;
    _year = years.contains(widget.today.year) ? widget.today.year : years.last;
    _jumpAfterFrame();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final days = heatmapDays(_year);
      var week = days.length ~/ 7 - 1;
      if (_year == widget.today.year) {
        final t = DateTime.utc(
            widget.today.year, widget.today.month, widget.today.day);
        final i = days.indexOf(t);
        if (i >= 0) week = i ~/ 7;
      }
      final target = (week * (_cell + _gap))
          .clamp(0.0, _controller.position.maxScrollExtent);
      _controller.jumpTo(target);
    });
  }

  Color _colorFor(MatchOutcome? o) => switch (o) {
        MatchOutcome.win => AppTheme.accentGreen,
        MatchOutcome.draw => AppTheme.accentGold,
        MatchOutcome.loss => AppTheme.accentRed,
        null => AppTheme.surfaceAlt,
      };

  @override
  Widget build(BuildContext context) {
    final years = widget.summary.activeYears;
    final days = heatmapDays(_year);
    final weeks = days.length ~/ 7;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final y in years)
                ChoiceChip(
                  label: Text('$y'),
                  selected: y == _year,
                  selectedColor: AppTheme.accentGreen.withValues(alpha: 0.25),
                  onSelected: (_) {
                    setState(() => _year = y);
                    _jumpAfterFrame();
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int w = 0; w < weeks; w++)
                  Padding(
                    padding: const EdgeInsets.only(right: _gap),
                    child: Column(
                      children: [
                        for (int d = 0; d < 7; d++) _cellFor(days[w * 7 + d]),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final o in MatchOutcome.values) ...[
                Container(
                  width: _cell,
                  height: _cell,
                  decoration: BoxDecoration(
                    color: _colorFor(o),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                FifaLabel(o.label, color: AppTheme.textSecondary, fontSize: 10),
                const SizedBox(width: 14),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _cellFor(DateTime day) {
    final inYear = day.year == _year;
    return Padding(
      padding: const EdgeInsets.only(bottom: _gap),
      child: Container(
        width: _cell,
        height: _cell,
        decoration: BoxDecoration(
          color: inYear
              ? _colorFor(widget.summary.outcomeByDay[day])
              : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
