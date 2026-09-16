import 'package:calcetto_tracker/core/util/seasonal_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeEasterSunday', () {
    test('matches known Easter dates', () {
      expect(computeEasterSunday(2024), DateTime(2024, 3, 31));
      expect(computeEasterSunday(2025), DateTime(2025, 4, 20));
      expect(computeEasterSunday(2026), DateTime(2026, 4, 5));
      expect(computeEasterSunday(2027), DateTime(2027, 3, 28));
      expect(computeEasterSunday(2000), DateTime(2000, 4, 23));
    });
  });

  group('resolveSeasonalTheme', () {
    test('December is entirely christmas', () {
      expect(resolveSeasonalTheme(DateTime(2026, 12, 1)),
          SeasonalTheme.christmas);
      expect(resolveSeasonalTheme(DateTime(2026, 12, 31)),
          SeasonalTheme.christmas);
    });

    test('boundaries around December are none', () {
      expect(resolveSeasonalTheme(DateTime(2026, 11, 30)), SeasonalTheme.none);
      expect(resolveSeasonalTheme(DateTime(2027, 1, 1)), SeasonalTheme.none);
    });

    test('October is entirely halloween', () {
      expect(resolveSeasonalTheme(DateTime(2026, 10, 1)),
          SeasonalTheme.halloween);
      expect(resolveSeasonalTheme(DateTime(2026, 10, 31)),
          SeasonalTheme.halloween);
    });

    test('boundaries around October are none', () {
      expect(resolveSeasonalTheme(DateTime(2026, 9, 30)), SeasonalTheme.none);
      expect(resolveSeasonalTheme(DateTime(2026, 11, 1)), SeasonalTheme.none);
    });

    test('June through August is entirely summer', () {
      expect(
          resolveSeasonalTheme(DateTime(2026, 6, 1)), SeasonalTheme.summer);
      expect(
          resolveSeasonalTheme(DateTime(2026, 7, 15)), SeasonalTheme.summer);
      expect(
          resolveSeasonalTheme(DateTime(2026, 8, 31)), SeasonalTheme.summer);
    });

    test('boundaries around summer are none', () {
      expect(resolveSeasonalTheme(DateTime(2026, 5, 31)), SeasonalTheme.none);
      expect(resolveSeasonalTheme(DateTime(2026, 9, 1)), SeasonalTheme.none);
    });

    test('Easter window (2026: Easter Sunday is April 5) is easter', () {
      // Finestra: 7 giorni prima di Pasqua fino a Pasquetta inclusa.
      expect(
          resolveSeasonalTheme(DateTime(2026, 3, 29)), SeasonalTheme.easter);
      expect(
          resolveSeasonalTheme(DateTime(2026, 4, 5)), SeasonalTheme.easter);
      expect(
          resolveSeasonalTheme(DateTime(2026, 4, 6)), SeasonalTheme.easter);
    });

    test('boundaries around the Easter window are none', () {
      expect(resolveSeasonalTheme(DateTime(2026, 3, 28)), SeasonalTheme.none);
      expect(resolveSeasonalTheme(DateTime(2026, 4, 7)), SeasonalTheme.none);
    });

    test('a neutral date outside any window is none', () {
      expect(
          resolveSeasonalTheme(DateTime(2026, 2, 14)), SeasonalTheme.none);
      expect(resolveSeasonalTheme(DateTime(2026, 5, 15)), SeasonalTheme.none);
    });
  });
}
