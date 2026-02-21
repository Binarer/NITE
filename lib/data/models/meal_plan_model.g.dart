// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MealEntryAdapter extends TypeAdapter<MealEntry> {
  @override
  final int typeId = AppConstants.mealEntryTypeId;

  @override
  MealEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealEntry(
      foodItemId: fields[0] as String,
      grams: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MealEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.foodItemId)
      ..writeByte(1)
      ..write(obj.grams);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealPlanModelAdapter extends TypeAdapter<MealPlanModel> {
  @override
  final int typeId = AppConstants.mealPlanTypeId;

  @override
  MealPlanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealPlanModel(
      id: fields[0] as String,
      name: fields[1] as String,
      entries: (fields[2] as Map).map(
        (k, v) => MapEntry(
          k as String,
          (v as List).cast<MealEntry>(),
        ),
      ),
      dailyCalorieTarget: fields[3] as double,
      dailyProteinTarget: fields[4] as double,
      dailyFatTarget: fields[5] as double,
      dailyCarbTarget: fields[6] as double,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MealPlanModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.entries)
      ..writeByte(3)
      ..write(obj.dailyCalorieTarget)
      ..writeByte(4)
      ..write(obj.dailyProteinTarget)
      ..writeByte(5)
      ..write(obj.dailyFatTarget)
      ..writeByte(6)
      ..write(obj.dailyCarbTarget)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealPlanModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
