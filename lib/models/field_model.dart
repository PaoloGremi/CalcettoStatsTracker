import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class FieldModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String address;

  @HiveField(3)
  String? imagePath;

  FieldModel({
    required this.id,
    required this.name,
    required this.address,
    this.imagePath,
  });
}

class FieldModelAdapter extends TypeAdapter<FieldModel> {
  @override
  final int typeId = 2;

  @override
  FieldModel read(BinaryReader reader) {
    final id      = reader.readString();
    final name    = reader.readString();
    final address = reader.readString();

    String? imagePath;
    try {
      final raw = reader.read();
      if (raw is String && raw.isNotEmpty) imagePath = raw;
    } catch (_) {}

    return FieldModel(id: id, name: name, address: address, imagePath: imagePath);
  }

  @override
  void write(BinaryWriter writer, FieldModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.address);
    writer.write(obj.imagePath ?? '');
  }
}
