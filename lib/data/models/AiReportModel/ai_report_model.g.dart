// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_report_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AiReportModelAdapter extends TypeAdapter<AiReportModel> {
  @override
  final int typeId = 7;

  @override
  AiReportModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AiReportModel(
      id: fields[0] as String,
      type: fields[1] as String,
      date: fields[2] as DateTime,
      content: fields[3] as String,
      createdAt: fields[4] as DateTime,
      caloriesConsumed: fields[5] as double?,
      weightKg: fields[6] as double?,
      tdee: fields[7] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, AiReportModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.caloriesConsumed)
      ..writeByte(6)
      ..write(obj.weightKg)
      ..writeByte(7)
      ..write(obj.tdee);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiReportModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
