import 'package:hive/hive.dart';
import '../models/player_model.dart';
import '../models/match_model.dart';
import '../models/field_model.dart';
import '../features/trainings/data/models/training_model.dart';

class HiveBoxes {
  static late Box<PlayerModel> playersBox;
  static late Box<MatchModel> matchesBox;
  static late Box<FieldModel> fieldsBox;
  static late Box<TrainingModel> trainingsBox;

  static Future<void> init() async {
    playersBox = await Hive.openBox<PlayerModel>('playersBox');
    matchesBox = await Hive.openBox<MatchModel>('matchesBox');
    fieldsBox = await Hive.openBox<FieldModel>('fieldsBox');
    trainingsBox = await Hive.openBox<TrainingModel>('trainingsBox');
  }
}
