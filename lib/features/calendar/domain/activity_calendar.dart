import '../../../models/match_model.dart';
import '../../trainings/domain/entities/training.dart';

/// Una voce del calendario: una partita o un allenamento.
sealed class CalendarEntry {
  const CalendarEntry();
  DateTime get date;
}

class MatchEntry extends CalendarEntry {
  const MatchEntry(this.match);
  final MatchModel match;
  @override
  DateTime get date => match.date;
}

class TrainingEntry extends CalendarEntry {
  const TrainingEntry(this.training);
  final Training training;
  @override
  DateTime get date => training.date;
}

/// Partite e allenamenti raggruppati per giorno. Con [playerId] tiene solo
/// le partite in cui quel giocatore era in campo; senza, tutte.
class ActivityCalendar {
  ActivityCalendar({
    required List<MatchModel> matches,
    required List<Training> trainings,
    String? playerId,
  }) {
    final played = playerId == null
        ? matches
        : matches.where(
            (m) => m.teamA.contains(playerId) || m.teamB.contains(playerId));
    // Prima le partite, poi gli allenamenti; ciascuno in ordine di orario.
    final sortedMatches = played.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final sortedTrainings = trainings.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final m in sortedMatches) {
      _byDay.putIfAbsent(_day(m.date), () => []).add(MatchEntry(m));
    }
    for (final t in sortedTrainings) {
      _byDay.putIfAbsent(_day(t.date), () => []).add(TrainingEntry(t));
    }
  }

  final Map<DateTime, List<CalendarEntry>> _byDay = {};

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Voci del giorno di [day] (l'orario è ignorato).
  List<CalendarEntry> entriesOn(DateTime day) => _byDay[_day(day)] ?? const [];

  /// Anni con almeno una voce.
  Set<int> get years => {for (final d in _byDay.keys) d.year};

  ({int matches, int trainings}) monthCounts(int year, int month) {
    var matches = 0, trainings = 0;
    for (final MapEntry(key: day, value: entries) in _byDay.entries) {
      if (day.year != year || day.month != month) continue;
      for (final e in entries) {
        switch (e) {
          case MatchEntry():
            matches++;
          case TrainingEntry():
            trainings++;
        }
      }
    }
    return (matches: matches, trainings: trainings);
  }
}
