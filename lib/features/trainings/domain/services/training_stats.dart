import '../entities/training.dart';

/// Un punto del grafico del passo.
class PacePoint {
  const PacePoint(this.date, this.secondsPerKm);

  final DateTime date;
  final double secondsPerKm;
}

/// Statistiche degli allenamenti, calcolate in Dart puro (niente Hive, niente
/// UI). Liste vuote producono null / zero, mai eccezioni.
///
/// I giorni sono confrontati come `DateTime.utc(y, m, d)`: così l'aritmetica
/// sui giorni non risente del cambio d'ora legale e le chiavi coincidono con
/// quelle di `heatmapDays()`.
class TrainingStats {
  TrainingStats(List<Training> trainings, {required DateTime today})
      : _trainings = List.unmodifiable(trainings),
        _today = _utcDay(today);

  static const minKmForBestPace = 1.0;

  final List<Training> _trainings;
  final DateTime _today;

  static DateTime _utcDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static DateTime _monday(DateTime utcDay) => DateTime.utc(
      utcDay.year, utcDay.month, utcDay.day - (utcDay.weekday - 1));

  static DateTime _minusWeek(DateTime monday) =>
      DateTime.utc(monday.year, monday.month, monday.day - 7);

  Iterable<Training> get _runs =>
      _trainings.where((t) => t.paceSecondsPerKm != null);

  double? get bestPaceSecondsPerKm {
    double? best;
    for (final t in _runs) {
      if (t.distanceKm! < minKmForBestPace) continue;
      final pace = t.paceSecondsPerKm!;
      if (best == null || pace < best) best = pace;
    }
    return best;
  }

  double? get longestRunKm {
    double? longest;
    for (final t in _runs) {
      if (longest == null || t.distanceKm! > longest) longest = t.distanceKm;
    }
    return longest;
  }

  late final Set<DateTime> _activeMondays =
      _trainings.map((t) => _monday(_utcDay(t.date))).toSet();

  late final int bestWeekStreak = () {
    final mondays = _activeMondays.toList()..sort();
    var best = 0, run = 0;
    DateTime? previous;
    for (final m in mondays) {
      run = (previous != null && _minusWeek(m) == previous) ? run + 1 : 1;
      if (run > best) best = run;
      previous = m;
    }
    return best;
  }();

  /// Serie in corso: la settimana attuale ancora vuota non la interrompe,
  /// purché la precedente abbia almeno un allenamento.
  late final int currentWeekStreak = () {
    var cursor = _monday(_today);
    if (!_activeMondays.contains(cursor)) cursor = _minusWeek(cursor);
    var count = 0;
    while (_activeMondays.contains(cursor)) {
      count++;
      cursor = _minusWeek(cursor);
    }
    return count;
  }();

  List<PacePoint> get pacePoints {
    final points = [
      for (final t in _runs)
        PacePoint(DateTime(t.date.year, t.date.month, t.date.day),
            t.paceSecondsPerKm!),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  /// Tipo per giorno; tipi diversi nello stesso giorno → misto.
  Map<DateTime, TrainingType> get dayTypes {
    final map = <DateTime, TrainingType>{};
    for (final t in _trainings) {
      final day = _utcDay(t.date);
      final existing = map[day];
      map[day] = (existing == null || existing == t.type)
          ? t.type
          : TrainingType.mixed;
    }
    return map;
  }

  List<int> get activeYears =>
      (_trainings.map((t) => t.date.year).toSet().toList()..sort());

  int get thisWeekCount {
    final monday = _monday(_today);
    final nextMonday = DateTime.utc(monday.year, monday.month, monday.day + 7);
    return _trainings.where((t) {
      final d = _utcDay(t.date);
      return !d.isBefore(monday) && d.isBefore(nextMonday);
    }).length;
  }

  Training? get latest {
    Training? latest;
    for (final t in _trainings) {
      if (latest == null || t.date.isAfter(latest.date)) latest = t;
    }
    return latest;
  }
}
