import 'entities/training.dart';

/// Ritorna il primo errore di validazione di [t], o null se è valido.
String? validateTraining(Training t, {required DateTime today}) {
  final day = DateTime(t.date.year, t.date.month, t.date.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  if (day.isAfter(todayDay)) return 'La data non può essere nel futuro';

  if (t.type.hasRun) {
    final km = t.distanceKm ?? 0;
    if (!km.isFinite || km <= 0) {
      return 'Inserisci una distanza maggiore di zero';
    }
    if ((t.runSeconds ?? 0) <= 0) {
      return 'Inserisci un tempo di corsa maggiore di zero';
    }
  }
  if (t.type.hasTechnical) {
    if ((t.durationMinutes ?? 0) <= 0) {
      return 'Inserisci una durata maggiore di zero';
    }
    if (t.categories.isEmpty) return 'Scegli almeno una categoria tecnica';
  }
  return null;
}
