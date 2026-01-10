// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingRecordAdapter extends TypeAdapter<TrainingRecord> {
  @override
  final typeId = 0;

  @override
  TrainingRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingRecord(
      id: fields[0] as String?,
      date: fields[1] as DateTime,
      activity: fields[2] as String,
      duration: fields[3] as String,
      comment: fields[4] as String?,
      location: fields[5] as String?,
      monthlyCount: (fields[6] as num).toInt(),
      createdAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.activity)
      ..writeByte(3)
      ..write(obj.duration)
      ..writeByte(4)
      ..write(obj.comment)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.monthlyCount)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
