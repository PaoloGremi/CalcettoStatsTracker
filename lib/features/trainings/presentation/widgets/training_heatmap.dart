import 'package:flutter/material.dart';

import '../../../../services/player_stats_summary.dart' show heatmapDays;
import '../../../../theme/app_theme.dart';
import '../../domain/entities/training.dart';
import 'training_list_tile.dart' show trainingTypeColor;

/// Calendario annuale dei giorni di allenamento, una colonna per settimana
/// (lun→dom), colorato per tipo. Stesso stile della heatmap partite.
class TrainingHeatmap extends StatefulWidget {
  const TrainingHeatmap({
    super.key,
    required this.dayTypes,
    required this.activeYears,
    required this.today,
  });

  /// Chiavi `DateTime.utc(y, m, d)`, come `heatmapDays()`.
  final Map<DateTime, TrainingType> dayTypes;
  final List<int> activeYears;
  final DateTime today;

  @override
  State<TrainingHeatmap> createState() => _TrainingHeatmapState();
}

class _TrainingHeatmapState extends State<TrainingHeatmap> {
  static const double _cell = 12, _gap = 3;

  final _controller = ScrollController();
  late int _year;

  List<int> get _years =>
      widget.activeYears.isEmpty ? [widget.today.year] : widget.activeYears;

  @override
  void initState() {
    super.initState();
    _year = _years.contains(widget.today.year) ? widget.today.year : _years.last;
    _jumpAfterFrame();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Porta in vista la settimana corrente (o la fine dell'anno scelto).
  void _jumpAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final days = heatmapDays(_year);
      var week = days.length ~/ 7 - 1;
      if (_year == widget.today.year) {
        final i = days.indexOf(DateTime.utc(
            widget.today.year, widget.today.month, widget.today.day));
        if (i >= 0) week = i ~/ 7;
      }
      final target =
          ((week + 1) * (_cell + _gap) - _controller.position.viewportDimension)
              .clamp(0.0, _controller.position.maxScrollExtent);
      _controller.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          if (_years.length > 1) ...[
            Wrap(
              spacing: 8,
              children: [
                for (final y in _years)
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
          ],
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
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final t in TrainingType.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: _cell,
                      height: _cell,
                      decoration: BoxDecoration(
                        color: trainingTypeColor(t),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(t.label,
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cellFor(DateTime day) {
    final type = widget.dayTypes[day];
    final Color color;
    if (day.year != _year) {
      color = Colors.transparent;
    } else {
      color = type == null ? AppTheme.surfaceAlt : trainingTypeColor(type);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: _gap),
      child: Container(
        width: _cell,
        height: _cell,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
