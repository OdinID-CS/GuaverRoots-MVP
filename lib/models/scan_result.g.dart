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
      description: fields[11] as String?,
      areaScanResults: (fields[12] as List?)?.cast<dynamic>(),
      overallSummary: fields[13] as String?,
      recommendation: fields[14] as String?,
      riskLevel: fields[15] as String?,
      totalSections: fields[16] as int?,
      healthySections: fields[17] as int?,
      diseasedSections: fields[18] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ScanResult obj) {
    writer
      ..writeByte(19)
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
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.description)
      ..writeByte(12)
      ..write(obj.areaScanResults)
      ..writeByte(13)
      ..write(obj.overallSummary)
      ..writeByte(14)
      ..write(obj.recommendation)
      ..writeByte(15)
      ..write(obj.riskLevel)
      ..writeByte(16)
      ..write(obj.totalSections)
      ..writeByte(17)
      ..write(obj.healthySections)
      ..writeByte(18)
      ..write(obj.diseasedSections);
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
