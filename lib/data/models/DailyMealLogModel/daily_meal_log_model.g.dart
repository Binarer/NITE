// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_meal_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyMealLogAdapter extends TypeAdapter<DailyMealLog> {
  @override
  final int typeId = 10;

  @override
  DailyMealLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyMealLog(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      entries: (fields[2] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<MealEntry>())),
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyMealLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.entries)
      ..writeByte(3)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyMealLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
