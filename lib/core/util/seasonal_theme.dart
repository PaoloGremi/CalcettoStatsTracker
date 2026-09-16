/// Tema stagionale automatico per gli effetti decorativi della splash screen.
///
/// Funzioni pure (nessuna dipendenza Flutter/UI), testabili passando una
/// [DateTime] esplicita invece di affidarsi a [DateTime.now()].
library;

enum SeasonalTheme { none, christmas, easter, halloween, summer }

/// Determina il tema stagionale attivo per la data indicata (default: oggi).
///
/// Le finestre non si sovrappongono mai (Pasqua cade sempre tra marzo e
/// aprile), quindi l'ordine dei controlli non è critico per la correttezza,
/// ma riflette comunque le festività "a mese fisso" prima di quella mobile:
/// - Dicembre (1–31) → Natale
/// - Ottobre (1–31) → Halloween
/// - Giugno–Agosto → Estate
/// - Da una settimana prima di Pasqua a Pasquetta inclusa → Pasqua
/// - Altrimenti → nessun tema
SeasonalTheme resolveSeasonalTheme([DateTime? now]) {
  final today = _dateOnly(now ?? DateTime.now());

  if (today.month == 12) return SeasonalTheme.christmas;
  if (today.month == 10) return SeasonalTheme.halloween;
  if (today.month >= 6 && today.month <= 8) return SeasonalTheme.summer;

  final easter = computeEasterSunday(today.year);
  final easterWindowStart = easter.subtract(const Duration(days: 7));
  final easterWindowEnd = easter.add(const Duration(days: 1)); // Pasquetta
  if (!today.isBefore(easterWindowStart) && !today.isAfter(easterWindowEnd)) {
    return SeasonalTheme.easter;
  }

  return SeasonalTheme.none;
}

/// Calcola la data della domenica di Pasqua per l'anno indicato, secondo
/// l'algoritmo "Anonymous Gregorian" (Meeus/Jones/Butcher) — solo aritmetica
/// intera, valido per il calendario gregoriano.
DateTime computeEasterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
