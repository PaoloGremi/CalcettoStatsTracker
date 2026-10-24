import 'package:hive/hive.dart';

import '../../../../data/hive_boxes.dart';
import '../models/training_model.dart';

/// Wrapper sottile sul box Hive degli allenamenti (chiave = id). Nei test si
/// passa un box aperto su una directory temporanea. Il box globale si legge
/// al primo uso, così il datasource si può creare prima di `HiveBoxes.init()`.
class TrainingLocalDataSource {
  TrainingLocalDataSource({Box<TrainingModel>? box}) : _injected = box;

  final Box<TrainingModel>? _injected;

  Box<TrainingModel> get _box => _injected ?? HiveBoxes.trainingsBox;

  List<TrainingModel> getAll() => _box.values.toList();

  Future<void> put(TrainingModel m) => _box.put(m.id, m);

  Future<void> delete(String id) => _box.delete(id);
}
