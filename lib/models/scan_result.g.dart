// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanResultAdapter extends TypeAdapter<ScanResult> {
  @override
  final int typeId = 0;

  @override
  ScanResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanResult(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      timestamp: fields[2] as DateTime,
      diseaseName: fields[3] as String?,
      confidence: fields[4] as double?,
      severity: fields[5] as String?,
      treatment: fields[6] as String?,
      urgency: fields[7] as String?,
      isAreaScan: fields[8] as bool,
      areaScanImages: (fields[9] as List?)?.cast<String>(),
      notes: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScanResult obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.diseaseName)
      ..writeByte(4)
      ..write(obj.confidence)
      ..writeByte(5)
      ..write(obj.severity)
      ..writeByte(6)
      ..write(obj.treatment)
      ..writeByte(7)
      ..write(obj.urgency)
      ..writeByte(8)
      ..write(obj.isAreaScan)
      ..writeByte(9)
      ..write(obj.areaScanImages)
      ..writeByte(10)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
