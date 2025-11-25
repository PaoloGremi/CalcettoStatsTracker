import 'package:hive/hive.dart';
import '../models/player.dart';
import '../models/match_model.dart';

class HiveBoxes {
  static late Box<Player> playersBox;
  static late Box<MatchModel> matchesBox;

  static Future<void> init() async {
    playersBox = await Hive.openBox<Player>('playersBox');
    matchesBox = await Hive.openBox<MatchModel>('matchesBox');
  }
}
