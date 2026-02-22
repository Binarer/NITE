// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 1;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      tagIds: (fields[3] as List).cast<String>(),
      priority: fields[4] as int,
      useAiPriority: fields[5] as bool,
      date: fields[6] as DateTime,
      startMinutes: fields[7] as int?,
      endMinutes: fields[8] as int?,
      sortOrder: fields[9] as int,
      foodItemId: fields[10] as String?,
      foodItemIds: (fields[13] as List?)?.cast<String>() ?? [],
      scenarioId: fields[11] as String?,
      isCompleted: fields[12] as bool,
      subtasks: (fields[14] as List?)?.cast<SubtaskModel>() ?? [],
      foodGrams: fields[15] as double? ?? 100.0,
      foodItemGrams: (fields[16] as Map?)?.cast<String, double>() ?? {},
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.tagIds)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.useAiPriority)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.startMinutes)
      ..writeByte(8)
      ..write(obj.endMinutes)
      ..writeByte(9)
      ..write(obj.sortOrder)
      ..writeByte(10)
      ..write(obj.foodItemId)
      ..writeByte(13)
      ..write(obj.foodItemIds)
      ..writeByte(11)
      ..write(obj.scenarioId)
      ..writeByte(12)
      ..write(obj.isCompleted)
      ..writeByte(14)
      ..write(obj.subtasks)
      ..writeByte(15)
      ..write(obj.foodGrams)
      ..writeByte(16)
      ..write(obj.foodItemGrams);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
