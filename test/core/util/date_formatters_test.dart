import 'package:calcetto_tracker/core/util/date_formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  final date = DateTime(2025, 7, 5, 21, 0);

  test('formatShortDate renders dd/MM', () {
    expect(formatShortDate(date), '05/07');
  });

  test('formatDayMonthYear renders d MMM yyyy in italian', () {
    expect(formatDayMonthYear(date), '5 lug 2025');
  });

  test('formatLongDate renders dd MMMM yyyy in italian', () {
    expect(formatLongDate(date), '05 luglio 2025');
  });

  test('formatMonthYearShort renders MMM yy in italian', () {
    expect(formatMonthYearShort(date), 'lug 25');
  });

  test('formatMonthYearFull renders MMMM yyyy in italian', () {
    expect(formatMonthYearFull(date), 'luglio 2025');
  });

  test('formatFullDateTime renders EEE dd MMM yyyy · HH:mm in italian', () {
    expect(formatFullDateTime(date), 'sab 05 lug 2025 · 21:00');
  });

  test('formatTime renders zero-padded HH:mm', () {
    expect(formatTime(DateTime(2025, 7, 5, 9, 5)), '09:05');
  });
}
