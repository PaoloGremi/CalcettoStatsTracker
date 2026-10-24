/// Tipo di allenamento individuale.
enum TrainingType {
  running('Corsa'),
  technical('Tecnico'),
  mixed('Misto');

  const TrainingType(this.label);

  final String label;

  /// L'allenamento comprende una parte di corsa (km + tempo).
  bool get hasRun => this != TrainingType.technical;

  /// L'allenamento comprende una parte tecnica (durata + categorie).
  bool get hasTechnical => this != TrainingType.running;
}

/// Macro categorie della parte tecnica.
enum TechnicalCategory {
  shots('Tiri'),
  sprint('Sprint'),
  endurance('Resistenza'),
  ballSkills('Tecnica palla'),
  strength('Forza');

  const TechnicalCategory(this.label);

  final String label;
}

/// Un allenamento fatto da soli. Nessuna dipendenza da Hive.
class Training {
  final String id;
  final DateTime date;
  final TrainingType type;

  /// Durata della sessione tecnica/mista, in minuti.
  final int? durationMinutes;
  final double? distanceKm;
  final int? runSeconds;
  final Set<TechnicalCategory> categories;
  final String? notes;

  const Training({
    required this.id,
    required this.date,
    required this.type,
    this.durationMinutes,
    this.distanceKm,
    this.runSeconds,
    this.categories = const {},
    this.notes,
  });

  /// Passo medio in secondi al km, null se manca la parte di corsa.
  double? get paceSecondsPerKm {
    final km = distanceKm, secs = runSeconds;
    if (km == null || secs == null || km <= 0 || secs <= 0) return null;
    return secs / km;
  }

  /// Durata complessiva: nella sola corsa coincide col tempo di corsa.
  int get totalMinutes => type.hasTechnical
      ? durationMinutes ?? 0
      : ((runSeconds ?? 0) / 60).round();

  /// Copia pronta da salvare: data senza orario, campi non pertinenti al
  /// tipo azzerati (es. un misto diventato corsa perde le categorie), note
  /// vuote → null.
  Training normalized() {
    final trimmed = notes?.trim();
    return Training(
      id: id,
      date: DateTime(date.year, date.month, date.day),
      type: type,
      durationMinutes: type.hasTechnical ? durationMinutes : null,
      distanceKm: type.hasRun ? distanceKm : null,
      runSeconds: type.hasRun ? runSeconds : null,
      categories: type.hasTechnical ? categories : const {},
      notes: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
  }

  Training copyWith({
    DateTime? date,
    TrainingType? type,
    int? durationMinutes,
    double? distanceKm,
    int? runSeconds,
    Set<TechnicalCategory>? categories,
    String? notes,
  }) {
    return Training(
      id: id,
      date: date ?? this.date,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      runSeconds: runSeconds ?? this.runSeconds,
      categories: categories ?? this.categories,
      notes: notes ?? this.notes,
    );
  }
}
