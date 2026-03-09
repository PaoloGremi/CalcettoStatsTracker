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

  @HiveField(3)
  String icon;

  @HiveField(4)
  String? imagePath;

  @HiveField(5)
  int mvpCount;      // ✅ quante volte MVP

  @HiveField(6)
  int hustleCount;   // ✅ quante volte Combattivo

  Player({
    required this.id,
    required this.name,
    required this.role,
    required this.icon,
    this.imagePath,
    this.mvpCount = 0,
    this.hustleCount = 0,
  });
}

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 0;

  @override
  Player read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final role = reader.readString();
    final icon = reader.readString();

    // imagePath — retrocompatibile
    String? imagePath;
    try {
      final raw = reader.read();
      if (raw is String && raw.isNotEmpty) imagePath = raw;
    } catch (_) {}

    // mvpCount — retrocompatibile (0 se non presente)
    int mvpCount = 0;
    try {
      final raw = reader.read();
      if (raw is int) mvpCount = raw;
    } catch (_) {}

    // hustleCount — retrocompatibile (0 se non presente)
    int hustleCount = 0;
    try {
      final raw = reader.read();
      if (raw is int) hustleCount = raw;
    } catch (_) {}

    return Player(
      id: id,
      name: name,
      role: role,
      icon: icon,
      imagePath: imagePath,
      mvpCount: mvpCount,
      hustleCount: hustleCount,
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.role);
    writer.writeString(obj.icon);
    writer.write(obj.imagePath ?? '');
    writer.write(obj.mvpCount);
    writer.write(obj.hustleCount);
  }
}
