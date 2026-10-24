import 'package:calcetto_tracker/features/trainings/presentation/training_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it_IT', null));

  group('parseRunTime', () {
    test('mm:ss', () => expect(parseRunTime('25:30'), 1530));
    test('h:mm:ss', () => expect(parseRunTime('1:02:05'), 3725));
    test('plain number is minutes', () => expect(parseRunTime('45'), 2700));
    test('spaces ignored', () => expect(parseRunTime(' 25 : 30 '), 1530));
    test('empty', () => expect(parseRunTime(''), isNull));
    test('text', () => expect(parseRunTime('abc'), isNull));
    test('seconds over 59', () => expect(parseRunTime('5:75'), isNull));
    test('minutes over 59 with hours',
        () => expect(parseRunTime('1:60:00'), isNull));
    test('zero', () => expect(parseRunTime('0:00'), isNull));
  });

  group('parseKm', () {
    test('comma', () => expect(parseKm('5,2'), 5.2));
    test('dot', () => expect(parseKm('5.2'), 5.2));
    test('empty', () => expect(parseKm(''), isNull));
    test('text', () => expect(parseKm('cinque'), isNull));
    test('zero', () => expect(parseKm('0'), isNull));
    test('negative', () => expect(parseKm('-3'), isNull));
    test('NaN', () => expect(parseKm('NaN'), isNull));
    test('overflow to infinity', () => expect(parseKm('1e400'), isNull));
  });

  group('formatting', () {
    test('formatKm decimal', () => expect(formatKm(5.2), '5,2'));
    test('formatKm integer', () => expect(formatKm(10.0), '10'));
    test('formatRunTime minutes', () => expect(formatRunTime(1530), '25:30'));
    test('formatRunTime hours', () => expect(formatRunTime(3725), '1:02:05'));
    test('formatPace rounds', () => expect(formatPace(312.4), '5:12'));
    test('formatPace carries seconds', () => expect(formatPace(299.6), '5:00'));
  });

  group('formatTrainingDay', () {
    final today = DateTime(2026, 10, 24, 18);
    test('today', () => expect(formatTrainingDay(DateTime(2026, 10, 24), today), 'Oggi'));
    test('yesterday',
        () => expect(formatTrainingDay(DateTime(2026, 10, 23), today), 'Ieri'));
    test('older', () =>
        expect(formatTrainingDay(DateTime(2026, 10, 5), today), '5 ott 2026'));
  });
}
