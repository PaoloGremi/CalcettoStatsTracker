import 'package:hive/hive.dart';

part 'player_model.g.dart';

@HiveType(typeId: 0)
class PlayerModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String role;

  @HiveField(3)
  String icon;

  @HiveField(4)
  String? imagePath;

  @HiveField(5)
  int mvpCount; // quante volte MVP

  @HiveField(6)
  int hustleCount; // quante volte Combattivo

  @HiveField(7)
  int bestGoalCount; // quante volte Best Goal

  @HiveField(8)
  int totalGoals; // gol totali segnati in tutte le partite

  PlayerModel({
    required this.id,
    required this.name,
    required this.role,
    required this.icon,
    this.imagePath,
    this.mvpCount = 0,
    this.hustleCount = 0,
    this.bestGoalCount = 0,
    this.totalGoals = 0,
  });
}
