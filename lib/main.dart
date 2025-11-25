import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'data/hive_boxes.dart';
import 'models/player.dart';
import 'models/match_model.dart';
import 'screens/home_screen.dart';
import 'services/data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(PlayerAdapter());
  Hive.registerAdapter(MatchModelAdapter());

  await HiveBoxes.init();

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
        theme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.green, // colore principale (app bar, bottoni)
            secondary: Colors.tealAccent,
          ),
          scaffoldBackgroundColor: Colors.black, // sfondo principale
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          cardColor: Colors.grey[900],
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.white70),
          ),
        ),
        home: const HomeScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
