import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/services/training_stats.dart';
import '../training_format.dart';

/// Record personali: passo migliore, corsa più lunga, serie di settimane.
class TrainingRecordsCard extends StatelessWidget {
  const TrainingRecordsCard({super.key, required this.stats});

  final TrainingStats stats;

  @override
  Widget build(BuildContext context) {
    final pace = stats.bestPaceSecondsPerKm;
    final longest = stats.longestRunKm;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          _Record(
            label: 'Passo migliore',
            value: pace == null ? '—' : '${formatPace(pace)}/km',
            color: AppTheme.accentBlue,
          ),
          _Record(
            label: 'Corsa più lunga',
            value: longest == null ? '—' : '${formatKm(longest)} km',
            color: AppTheme.accentGreen,
          ),
          _Record(
            label: 'Serie settimane',
            value: '${stats.currentWeekStreak}',
            caption: 'record ${stats.bestWeekStreak}',
            color: AppTheme.accentGold,
          ),
        ],
      ),
    );
  }
}

class _Record extends StatelessWidget {
  const _Record({
    required this.label,
    required this.value,
    required this.color,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            if (caption != null)
              Text(caption!,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          ],
        ),
      );
}
