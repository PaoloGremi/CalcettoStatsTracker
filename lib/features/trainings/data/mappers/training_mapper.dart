import '../../domain/entities/training.dart';
import '../models/training_model.dart';

/// Converte tra [TrainingModel] (Hive) e [Training] (dominio). Nomi
/// sconosciuti in lettura: categoria ignorata, tipo trattato come misto.
class TrainingMapper {
  const TrainingMapper();

  Training toEntity(TrainingModel m) {
    final type = TrainingType.values
            .where((t) => t.name == m.type)
            .firstOrNull ??
        TrainingType.mixed;
    final byName = {for (final c in TechnicalCategory.values) c.name: c};
    return Training(
      id: m.id,
      date: m.date,
      type: type,
      durationMinutes: m.durationMinutes,
      distanceKm: m.distanceKm,
      runSeconds: m.runSeconds,
      categories: {
        for (final name in m.categories)
          if (byName[name] != null) byName[name]!,
      },
      notes: m.notes,
    );
  }

  TrainingModel toModel(Training t) => TrainingModel(
        id: t.id,
        date: t.date,
        type: t.type.name,
        durationMinutes: t.durationMinutes,
        distanceKm: t.distanceKm,
        runSeconds: t.runSeconds,
        categories: [for (final c in t.categories) c.name],
        notes: t.notes,
      );
}
