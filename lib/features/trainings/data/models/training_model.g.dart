// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingModelAdapter extends TypeAdapter<TrainingModel> {
  @override
  final int typeId = 3;

  @override
  TrainingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      type: fields[2] as String,
      durationMinutes: fields[3] as int?,
      distanceKm: fields[4] as double?,
      runSeconds: fields[5] as int?,
      categories: (fields[6] as List).cast<String>(),
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.distanceKm)
      ..writeByte(5)
      ..write(obj.runSeconds)
      ..writeByte(6)
      ..write(obj.categories)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
