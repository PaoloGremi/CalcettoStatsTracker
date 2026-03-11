import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'data/hive_boxes.dart';
import 'models/player.dart';
import 'models/match_model.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'services/data_service.dart';
import 'theme/app_theme.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initializeDateFormatting('it_IT', null);
  await Hive.initFlutter();
  Hive.registerAdapter(PlayerAdapter());
  Hive.registerAdapter(MatchModelAdapter());
  await HiveBoxes.init();

  FlutterNativeSplash.remove(); // rimuove splash nativo, parte Flutter

  runApp(const CalcettoApp());
}

class CalcettoApp extends StatelessWidget {
  const CalcettoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataService>(create: (_) => DataService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Champions Calcetto Stats',
        theme: AppTheme.theme,
        darkTheme: AppTheme.theme,
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
        routes: {'/home': (context) => const HomeScreen()},
      ),
    );
  }
}
