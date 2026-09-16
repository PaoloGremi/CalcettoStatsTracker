import 'package:calcetto_tracker/core/util/seasonal_theme.dart';
import 'package:calcetto_tracker/widgets/seasonal_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final theme in SeasonalTheme.values) {
    testWidgets('SeasonalOverlay renders without error for $theme',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: SeasonalOverlay(theme: theme),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  }
}
