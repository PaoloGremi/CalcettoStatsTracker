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

  /// Path assoluto dell'immagine copiata nella cartella app (può essere null)
  @HiveField(4)
  String? imagePath;

  Player({
    required this.id,
    required this.name,
    required this.role,
    required this.icon,
    this.imagePath,
  });
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
    final icon = reader.readString();
    // ✅ Campo nuovo: legge imagePath se presente, altrimenti null (retrocompatibile)
    String? imagePath;
    try {
      final raw = reader.read();
      if (raw is String && raw.isNotEmpty) {
        imagePath = raw;
      }
    } catch (_) {
      imagePath = null;
    }
    return Player(id: id, name: name, role: role, icon: icon, imagePath: imagePath);
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.role);
    writer.writeString(obj.icon);
    writer.write(obj.imagePath ?? '');
  }
}
