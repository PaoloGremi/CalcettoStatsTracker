import 'dart:math';

import 'package:hive/hive.dart';

enum role { P, D, C, A }

@HiveType(typeId: 0)
class Player extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String role;

  Player({required this.id, required this.name, required this.role});
}

// Adapter manuale per Hive
class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 0;

  @override
  Player read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final role = reader.readString();
    return Player(id: id, name: name, role: role);
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.role);
  }

}
