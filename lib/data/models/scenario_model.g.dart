// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenario_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScenarioTaskAdapter extends TypeAdapter<ScenarioTask> {
  @override
  final int typeId = 4;

  @override
  ScenarioTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScenarioTask(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      weekday: fields[3] as int,
      tagIds: (fields[4] as List).cast<String>(),
      priority: fields[5] as int,
      useAiPriority: fields[6] as bool,
      startMinutes: fields[7] as int?,
      endMinutes: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ScenarioTask obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.weekday)
      ..writeByte(4)
      ..write(obj.tagIds)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.useAiPriority)
      ..writeByte(7)
      ..write(obj.startMinutes)
      ..writeByte(8)
      ..write(obj.endMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScenarioTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScenarioModelAdapter extends TypeAdapter<ScenarioModel> {
  @override
  final int typeId = 3;

  @override
  ScenarioModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScenarioModel(
      id: fields[0] as String,
      name: fields[1] as String,
      tasks: (fields[2] as List).cast<ScenarioTask>(),
    );
  }

  @override
  void write(BinaryWriter writer, ScenarioModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.tasks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScenarioModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
