import 'package:calcetto_tracker/screens/calendar_match_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() => initializeDateFormatting('it_IT'));

  testWidgets('opens scrolled to the current month', (tester) async {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM', 'it_IT')
        .format(DateTime(now.year, now.month))
        .toUpperCase();

    await tester.pumpWidget(
        const MaterialApp(home: CalendarMatchScreen(matches: [])));
    await tester.pumpAndSettle();

    final header = find.textContaining(monthName);
    expect(header, findsWidgets);
    final screen = tester.getRect(find.byType(Scaffold));
    expect(screen.contains(tester.getCenter(header.first)), isTrue);
  });
}
