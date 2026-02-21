// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MacroNutrientsAdapter extends TypeAdapter<MacroNutrients> {
  @override
  final int typeId = 5;

  @override
  MacroNutrients read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MacroNutrients(
      proteins: fields[0] as double,
      fats: fields[1] as double,
      carbs: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MacroNutrients obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.proteins)
      ..writeByte(1)
      ..write(obj.fats)
      ..writeByte(2)
      ..write(obj.carbs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroNutrientsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FoodItemModelAdapter extends TypeAdapter<FoodItemModel> {
  @override
  final int typeId = 2;

  @override
  FoodItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodItemModel(
      id: fields[0] as String,
      name: fields[1] as String,
      photoPath: fields[2] as String?,
      description: fields[3] as String,
      calories: fields[4] as double,
      macros: fields[5] as MacroNutrients,
      isHidden: fields[6] == null ? false : fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, FoodItemModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.photoPath)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.calories)
      ..writeByte(5)
      ..write(obj.macros)
      ..writeByte(6)
      ..write(obj.isHidden);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
