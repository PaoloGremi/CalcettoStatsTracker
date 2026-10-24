import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Gestisce la scelta tema chiaro/scuro e la persiste in SharedPreferences.
///
/// La palette vive in [AppTheme] come stato statico: qui la si aggiorna e si
/// notifica l'app, che ricostruisce l'intero albero (vedi `CalcettoApp`).
class ThemeController extends ChangeNotifier {
  static const prefsKey = 'theme_light';

  bool get isLight => AppTheme.isLight;

  /// Da chiamare in `main()` prima di `runApp`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    AppTheme.isLight = prefs.getBool(prefsKey) ?? false;
  }

  Future<void> setLight(bool value) async {
    if (value == AppTheme.isLight) return;
    AppTheme.isLight = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, value);
  }
}
