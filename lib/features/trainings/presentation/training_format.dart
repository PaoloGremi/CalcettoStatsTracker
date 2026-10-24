import 'package:intl/intl.dart';

import '../../../core/util/date_formatters.dart';

/// Tempo di corsa in secondi da `mm:ss`, `h:mm:ss` o un numero di minuti.
/// Null se vuoto, non valido o zero.
int? parseRunTime(String input) {
  final s = input.replaceAll(' ', '');
  if (s.isEmpty) return null;
  final parts = s.split(':');
  if (parts.length > 3) return null;
  final nums = <int>[];
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null || n < 0) return null;
    nums.add(n);
  }
  final int total;
  switch (nums.length) {
    case 1:
      total = nums[0] * 60;
    case 2:
      if (nums[1] > 59) return null;
      total = nums[0] * 60 + nums[1];
    default:
      if (nums[1] > 59 || nums[2] > 59) return null;
      total = nums[0] * 3600 + nums[1] * 60 + nums[2];
  }
  return total > 0 ? total : null;
}

/// Km da testo con virgola o punto decimale. Null se vuoto, non valido o ≤ 0.
double? parseKm(String input) {
  final value = double.tryParse(input.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite || value <= 0) return null;
  return value;
}

/// `5,2`, `10`.
String formatKm(double km) => NumberFormat('#0.##', 'it_IT').format(km);

String _two(int n) => n.toString().padLeft(2, '0');

/// `25:30` o `1:02:05`.
String formatRunTime(int seconds) {
  final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
  return h > 0 ? '$h:${_two(m)}:${_two(s)}' : '$m:${_two(s)}';
}

/// Passo `m:ss` (senza `/km`), arrotondato al secondo.
String formatPace(double secondsPerKm) {
  final total = secondsPerKm.round();
  return '${total ~/ 60}:${_two(total % 60)}';
}

/// `Oggi`, `Ieri` o `5 ott 2026`.
String formatTrainingDay(DateTime date, DateTime today) {
  final d = DateTime.utc(date.year, date.month, date.day);
  final t = DateTime.utc(today.year, today.month, today.day);
  final diff = t.difference(d).inDays;
  if (diff == 0) return 'Oggi';
  if (diff == 1) return 'Ieri';
  return formatDayMonthYear(date);
}
