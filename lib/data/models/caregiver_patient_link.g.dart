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
      linkedAt: fields[3] as DateTime,
      patientEmail: fields[4] as String?,
      caregiverEmail: fields[5] as String?,
      patientName: fields[6] as String?,
      caregiverName: fields[7] as String?,
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
      ..write(obj.linkedAt)
      ..writeByte(4)
      ..write(obj.patientEmail)
      ..writeByte(5)
      ..write(obj.caregiverEmail)
      ..writeByte(6)
      ..write(obj.patientName)
      ..writeByte(7)
      ..write(obj.caregiverName);
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
      linkedAt: DateTime.parse(json['linked_at'] as String),
      patientEmail: json['patient_email'] as String?,
      caregiverEmail: json['caregiver_email'] as String?,
      patientName: json['patient_name'] as String?,
      caregiverName: json['caregiver_name'] as String?,
    );

Map<String, dynamic> _$CaregiverPatientLinkToJson(
        CaregiverPatientLink instance) =>
    <String, dynamic>{
      'id': instance.id,
      'caregiver_id': instance.caregiverId,
      'patient_id': instance.patientId,
      'linked_at': instance.linkedAt.toIso8601String(),
      'patient_email': instance.patientEmail,
      'caregiver_email': instance.caregiverEmail,
      'patient_name': instance.patientName,
      'caregiver_name': instance.caregiverName,
    };
