import 'package:hive/hive.dart';

import '../../../../data/hive_boxes.dart';
import '../models/training_model.dart';

/// Wrapper sottile sul box Hive degli allenamenti (chiave = id). Nei test si
/// passa un box aperto su una directory temporanea.
class TrainingLocalDataSource {
  TrainingLocalDataSource({Box<TrainingModel>? box})
      : _box = box ?? HiveBoxes.trainingsBox;

  final Box<TrainingModel> _box;

  List<TrainingModel> getAll() => _box.values.toList();

  Future<void> put(TrainingModel m) => _box.put(m.id, m);

  Future<void> delete(String id) => _box.delete(id);
}
