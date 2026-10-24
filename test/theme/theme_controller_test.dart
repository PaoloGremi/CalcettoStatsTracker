import 'package:calcetto_tracker/theme/app_theme.dart';
import 'package:calcetto_tracker/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => AppTheme.isLight = false);

  test('defaults to dark when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    await ThemeController().load();

    expect(AppTheme.isLight, isFalse);
    expect(AppTheme.theme.brightness, Brightness.dark);
  });

  test('loads the saved light preference', () async {
    SharedPreferences.setMockInitialValues({ThemeController.prefsKey: true});
    await ThemeController().load();

    expect(AppTheme.isLight, isTrue);
    expect(AppTheme.theme.brightness, Brightness.light);
  });

  test('setLight switches palette, notifies and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();
    var notified = 0;
    controller.addListener(() => notified++);
    final darkBg = AppTheme.bg;

    await controller.setLight(true);

    expect(controller.isLight, isTrue);
    expect(AppTheme.bg, isNot(darkBg));
    expect(notified, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(ThemeController.prefsKey), isTrue);
  });

  test('setLight with the current value does not notify', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.setLight(false);

    expect(notified, 0);
  });
}
