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
      // status: fields[3] as ConnectionStatus,
      // createdAt: fields[4] as DateTime,
      // acceptedAt: fields[5] as DateTime?,
      patientEmail: fields[6] as String?,
      caregiverEmail: fields[7] as String?,
      patientName: fields[8] as String?,
      caregiverName: fields[9] as String?, linkedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CaregiverPatientLink obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.caregiverId)
      ..writeByte(2)
      ..write(obj.patientId)
      // ..writeByte(3)
      // ..write(obj.status)
      // ..writeByte(4)
      // ..write(obj.createdAt)
      // ..writeByte(5)
      // ..write(obj.acceptedAt)
      ..writeByte(6)
      ..write(obj.patientEmail)
      ..writeByte(7)
      ..write(obj.caregiverEmail)
      ..writeByte(8)
      ..write(obj.patientName)
      ..writeByte(9)
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
      // status: $enumDecode(_$ConnectionStatusEnumMap, json['status']),
      // createdAt: DateTime.parse(json['created_at'] as String),
      // acceptedAt: json['accepted_at'] == null
      // ? null
      // : DateTime.parse(json['accepted_at'] as String),
      patientEmail: json['patient_email'] as String?,
      caregiverEmail: json['caregiver_email'] as String?,
      patientName: json['patient_name'] as String?,
      caregiverName: json['caregiver_name'] as String?,
      linkedAt: DateTime.parse(json['linked_at'] as String),
    );

Map<String, dynamic> _$CaregiverPatientLinkToJson(
        CaregiverPatientLink instance) =>
    <String, dynamic>{
      'id': instance.id,
      'caregiver_id': instance.caregiverId,
      'patient_id': instance.patientId,
      // 'status': _$ConnectionStatusEnumMap[instance.status]!,
      // 'created_at': instance.createdAt.toIso8601String(),
      // 'accepted_at': instance.acceptedAt?.toIso8601String(),
      'patient_email': instance.patientEmail,
      'caregiver_email': instance.caregiverEmail,
      'patient_name': instance.patientName,
      'caregiver_name': instance.caregiverName,
    };

const _$ConnectionStatusEnumMap = {
  // ConnectionStatus.pending: 'pending',
  // ConnectionStatus.accepted: 'accepted',
  // ConnectionStatus.rejected: 'rejected',
};
