// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerModelAdapter extends TypeAdapter<PlayerModel> {
  @override
  final int typeId = 0;

  @override
  PlayerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerModel(
      id: fields[0] as String,
      name: fields[1] as String,
      role: fields[2] as String,
      icon: fields[3] as String,
      imagePath: fields[4] as String?,
      mvpCount: fields[5] as int,
      hustleCount: fields[6] as int,
      bestGoalCount: fields[7] as int,
      totalGoals: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.imagePath)
      ..writeByte(5)
      ..write(obj.mvpCount)
      ..writeByte(6)
      ..write(obj.hustleCount)
      ..writeByte(7)
      ..write(obj.bestGoalCount)
      ..writeByte(8)
      ..write(obj.totalGoals);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
