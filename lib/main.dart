import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/migration/hive_migration_service.dart';
import 'data/hive_boxes.dart';
import 'models/match_model.dart';
import 'models/field_model.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'services/data_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initializeDateFormatting('it_IT', null);
  await Hive.initFlutter();
  await HiveMigrationService.migratePlayersIfNeeded();
  Hive.registerAdapter(MatchModelAdapter());
  Hive.registerAdapter(FieldModelAdapter());
  await HiveBoxes.init();
  setupServiceLocator();
  await getIt<ThemeController>().load();

  FlutterNativeSplash.remove(); // rimuove splash nativo, parte Flutter

  runApp(const CalcettoApp());
}

class CalcettoApp extends StatefulWidget {
  const CalcettoApp({super.key});

  @override
  State<CalcettoApp> createState() => _CalcettoAppState();
}

class _CalcettoAppState extends State<CalcettoApp> {
  final _themeController = getIt<ThemeController>();

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  /// I colori di [AppTheme] sono statici: i widget che li leggono non
  /// dipendono da `Theme.of`, quindi forziamo il rebuild di tutto l'albero
  /// (route già aperte comprese) mantenendo lo stato e la navigazione.
  void _onThemeChanged() {
    setState(() {});
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataService>(
            create: (_) => getIt<DataService>()),
        ChangeNotifierProvider<ThemeController>.value(value: _themeController),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Champions Calcetto Stats',
        theme: AppTheme.theme,
        home: const SplashScreen(),
        routes: {'/home': (context) => const HomeScreen()},
      ),
    );
  }
}
