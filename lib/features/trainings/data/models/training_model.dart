import 'package:hive/hive.dart';

part 'training_model.g.dart';

/// Record Hive di un allenamento. `type` e `categories` sono salvati come
/// nomi degli enum (non indici), così riordinarli non rompe i dati.
@HiveType(typeId: 3)
class TrainingModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String type;

  @HiveField(3)
  int? durationMinutes;

  @HiveField(4)
  double? distanceKm;

  @HiveField(5)
  int? runSeconds;

  @HiveField(6)
  List<String> categories;

  @HiveField(7)
  String? notes;

  TrainingModel({
    required this.id,
    required this.date,
    required this.type,
    this.durationMinutes,
    this.distanceKm,
    this.runSeconds,
    this.categories = const [],
    this.notes,
  });
}
