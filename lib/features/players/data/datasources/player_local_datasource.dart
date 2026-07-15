import 'package:hive/hive.dart';

import '../../../../data/hive_boxes.dart';
import '../../../../models/player_model.dart';

/// Wrapper sottile sul box Hive dei giocatori. Isola il repository dalla
/// forma esatta di accesso allo storage (oggi Hive, in astratto
/// sostituibile) e rende il repository testabile passando un box aperto
/// su una directory temporanea invece del box globale dell'app.
class PlayerLocalDataSource {
  PlayerLocalDataSource({Box<PlayerModel>? box})
      : _box = box ?? HiveBoxes.playersBox;

  final Box<PlayerModel> _box;

  List<PlayerModel> getAll() => _box.values.toList();
}
