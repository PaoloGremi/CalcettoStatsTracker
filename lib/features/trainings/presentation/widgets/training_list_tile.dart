import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/entities/training.dart';
import '../training_format.dart';

/// Colore associato a un tipo di allenamento (heatmap, storico, legenda).
Color trainingTypeColor(TrainingType type) => switch (type) {
      TrainingType.running => AppTheme.accentBlue,
      TrainingType.walking => AppTheme.accentGold,
      TrainingType.technical => AppTheme.accentOrange,
      TrainingType.mixed => AppTheme.accentGreen,
    };

IconData trainingTypeIcon(TrainingType type) => switch (type) {
      TrainingType.running => Icons.directions_run_rounded,
      TrainingType.walking => Icons.directions_walk_rounded,
      TrainingType.technical => Icons.sports_soccer_rounded,
      TrainingType.mixed => Icons.fitness_center_rounded,
    };

/// Dettagli di un allenamento: `5,2 km · 25:30 · 4:54/km · 60 min · Tiri`.
String trainingDetails(Training t) {
  final parts = <String>[];
  if (t.type.hasDistance && t.distanceKm != null && t.runSeconds != null) {
    parts
      ..add('${formatKm(t.distanceKm!)} km')
      ..add(formatRunTime(t.runSeconds!));
    final pace = t.paceSecondsPerKm;
    if (pace != null) parts.add('${formatPace(pace)}/km');
  }
  if (t.type.hasTechnical) {
    if (t.durationMinutes != null) parts.add('${t.durationMinutes} min');
    final cats = TechnicalCategory.values
        .where(t.categories.contains)
        .map((c) => c.label)
        .join(', ');
    if (cats.isNotEmpty) parts.add(cats);
  }
  return parts.join(' · ');
}

/// Riga dello storico allenamenti.
class TrainingListTile extends StatelessWidget {
  const TrainingListTile({
    super.key,
    required this.training,
    required this.today,
    required this.onTap,
  });

  final Training training;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = trainingTypeColor(training.type);
    return Card(
      color: AppTheme.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(trainingTypeIcon(training.type), color: color, size: 20),
        ),
        title: Text(
          '${formatTrainingDay(training.date, today)} · ${training.type.label}',
          style: TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(trainingDetails(training),
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ),
    );
  }
}
