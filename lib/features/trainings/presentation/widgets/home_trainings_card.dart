import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/entities/training.dart';
import '../controllers/trainings_controller.dart';
import '../pages/trainings_page.dart';
import '../training_format.dart';
import 'training_list_tile.dart' show trainingTypeColor, trainingTypeIcon;

/// Riepilogo compatto per la home: `Ieri · Corsa 5,2 km · 5:12/km`.
String homeTrainingSummary(Training t, DateTime today) {
  final head = '${formatTrainingDay(t.date, today)} · ${t.type.label}';
  final pace = t.paceSecondsPerKm;
  if (t.type.hasDistance && t.distanceKm != null && pace != null) {
    return '$head ${formatKm(t.distanceKm!)} km · ${formatPace(pace)}/km';
  }
  if (t.durationMinutes != null) return '$head ${t.durationMinutes} min';
  return head;
}

/// Striscia "Allenamenti" della home, altezza fissa. Il controller è della
/// home: lo stesso usato dal + per un nuovo allenamento, così la card si
/// aggiorna da sola dopo un salvataggio.
class HomeTrainingsCard extends StatelessWidget {
  const HomeTrainingsCard({super.key, required this.controller});

  final TrainingsController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final latest = controller.stats.latest;
        final color = latest == null
            ? AppTheme.accentGreen
            : trainingTypeColor(latest.type);
        return Material(
          color: AppTheme.surface,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => TrainingsPage(controller: controller)),
            ),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Icon(
                      latest == null
                          ? Icons.directions_run_rounded
                          : trainingTypeIcon(latest.type),
                      color: color,
                      size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latest == null
                              ? 'Registra il tuo primo allenamento'
                              : homeTrainingSummary(latest, controller.today),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                        if (latest != null)
                          Text(
                            '${controller.stats.thisWeekCount} questa settimana',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textMuted, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
