// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caregiver_patient_link.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CaregiverPatientLinkAdapter extends TypeAdapter<CaregiverPatientLink> {
  @override
  final int typeId = 7;

  @override
  CaregiverPatientLink read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CaregiverPatientLink(
      id: fields[0] as String,
      caregiverId: fields[1] as String,
      patientId: fields[2] as String,
      patientName: fields[3] as String,
      patientPhotoUrl: fields[4] as String?,
      relationship: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      isPrimary: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CaregiverPatientLink obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.caregiverId)
      ..writeByte(2)
      ..write(obj.patientId)
      ..writeByte(3)
      ..write(obj.patientName)
      ..writeByte(4)
      ..write(obj.patientPhotoUrl)
      ..writeByte(5)
      ..write(obj.relationship)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isPrimary);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaregiverPatientLinkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CaregiverPatientLink _$CaregiverPatientLinkFromJson(
        Map<String, dynamic> json) =>
    CaregiverPatientLink(
      id: json['id'] as String,
      caregiverId: json['caregiver_id'] as String,
      patientId: json['patient_id'] as String,
      patientName: json['patient_name'] as String,
      patientPhotoUrl: json['patient_photo_url'] as String?,
      relationship: json['relationship'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPrimary: json['is_primary'] as bool? ?? false,
    );

Map<String, dynamic> _$CaregiverPatientLinkToJson(
        CaregiverPatientLink instance) =>
    <String, dynamic>{
      'id': instance.id,
      'caregiver_id': instance.caregiverId,
      'patient_id': instance.patientId,
      'patient_name': instance.patientName,
      'patient_photo_url': instance.patientPhotoUrl,
      'relationship': instance.relationship,
      'created_at': instance.createdAt.toIso8601String(),
      'is_primary': instance.isPrimary,
    };
