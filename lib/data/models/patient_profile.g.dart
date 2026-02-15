// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PatientProfileAdapter extends TypeAdapter<PatientProfile> {
  @override
  final int typeId = 8;

  @override
  PatientProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatientProfile(
      id: fields[0] as String,
      fullName: fields[1] as String,
      dateOfBirth: fields[2] as DateTime?,
      gender: fields[3] as String?,
      phoneNumber: fields[4] as String?,
      address: fields[5] as String?,
      emergencyContactName: fields[6] as String?,
      emergencyContactPhone: fields[7] as String?,
      medicalNotes: fields[8] as String?,
      profileImageUrl: fields[9] as String?,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
      isSynced: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PatientProfile obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.dateOfBirth)
      ..writeByte(3)
      ..write(obj.gender)
      ..writeByte(4)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.emergencyContactName)
      ..writeByte(7)
      ..write(obj.emergencyContactPhone)
      ..writeByte(8)
      ..write(obj.medicalNotes)
      ..writeByte(9)
      ..write(obj.profileImageUrl)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatientProfile _$PatientProfileFromJson(Map<String, dynamic> json) =>
    PatientProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String?,
      phoneNumber: json['phone_number'] as String?,
      address: json['address'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      medicalNotes: json['medical_notes'] as String?,
      profileImageUrl: json['profile_photo_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PatientProfileToJson(PatientProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'date_of_birth': instance.dateOfBirth?.toIso8601String(),
      'gender': instance.gender,
      'phone_number': instance.phoneNumber,
      'address': instance.address,
      'emergency_contact_name': instance.emergencyContactName,
      'emergency_contact_phone': instance.emergencyContactPhone,
      'medical_notes': instance.medicalNotes,
      'profile_photo_url': instance.profileImageUrl,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
