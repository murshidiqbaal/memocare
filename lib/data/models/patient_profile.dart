import 'package:json_annotation/json_annotation.dart';

part 'patient_profile.g.dart';

@JsonSerializable()
class PatientProfile {
  final String id;

  @JsonKey(name: 'user_id')
  final String? userId;

  @JsonKey(name: 'full_name')
  final String? fullName;

  @JsonKey(name: 'date_of_birth')
  final DateTime? dateOfBirth;

  final String? gender;

  @JsonKey(name: 'phone')
  final String? phoneNumber;

  final String? address;

  @JsonKey(name: 'emergency_contact_name')
  final String? emergencyContactName;

  @JsonKey(name: 'emergency_contact_phone')
  final String? emergencyContactPhone;

  @JsonKey(name: 'medical_notes')
  final String? medicalNotes;

  @JsonKey(name: 'profile_photo_url')
  final String? profileImageUrl;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @JsonKey(name: 'biometric_enabled')
  final bool? biometricEnabled;

  @JsonKey(name: 'trusted_device_id')
  final String? trustedDeviceId;

  @JsonKey(name: 'last_biometric_login')
  final DateTime? lastBiometricLogin;

  // ── Hobbies & Interests ───────────────────────────────────
  final List<String>? hobbies;

  @JsonKey(name: 'favourite_pastime')
  final String? favouritePastime;

  @JsonKey(name: 'indoor_outdoor_pref')
  final String? indoorOutdoorPref;

  // ── Favourite Things ──────────────────────────────────────
  @JsonKey(name: 'favourite_food')
  final String? favouriteFood;

  @JsonKey(name: 'favourite_drink')
  final String? favouriteDrink;

  @JsonKey(name: 'favourite_music')
  final String? favouriteMusic;

  @JsonKey(name: 'favourite_show')
  final String? favouriteShow;

  @JsonKey(name: 'favourite_place')
  final String? favouritePlace;

  // ── Daily Routine ─────────────────────────────────────────
  @JsonKey(name: 'wake_up_time')
  final String? wakeUpTime;

  @JsonKey(name: 'bed_time')
  final String? bedTime;

  @JsonKey(name: 'meal_preferences')
  final String? mealPreferences;

  @JsonKey(name: 'exercise_routine')
  final String? exerciseRoutine;

  @JsonKey(name: 'religious_practices')
  final String? religiousPractices;

  @JsonKey(name: 'nap_time')
  final String? napTime;

  // ── Language & Communication ──────────────────────────────
  @JsonKey(name: 'preferred_language')
  final String? preferredLanguage;

  @JsonKey(name: 'communication_style')
  final String? communicationStyle;

  final String? triggers;

  @JsonKey(name: 'calming_strategies')
  final String? calmingStrategies;

  @JsonKey(name: 'important_people')
  final String? importantPeople;

  PatientProfile({
    required this.id,
    this.userId,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.medicalNotes,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
    this.biometricEnabled,
    this.trustedDeviceId,
    this.lastBiometricLogin,
    // new
    this.hobbies,
    this.favouritePastime,
    this.indoorOutdoorPref,
    this.favouriteFood,
    this.favouriteDrink,
    this.favouriteMusic,
    this.favouriteShow,
    this.favouritePlace,
    this.wakeUpTime,
    this.bedTime,
    this.mealPreferences,
    this.exerciseRoutine,
    this.religiousPractices,
    this.napTime,
    this.preferredLanguage,
    this.communicationStyle,
    this.triggers,
    this.calmingStrategies,
    this.importantPeople,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) =>
      _$PatientProfileFromJson(json);

  Map<String, dynamic> toJson() => _$PatientProfileToJson(this);

  PatientProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? medicalNotes,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? biometricEnabled,
    String? trustedDeviceId,
    DateTime? lastBiometricLogin,
    List<String>? hobbies,
    String? favouritePastime,
    String? indoorOutdoorPref,
    String? favouriteFood,
    String? favouriteDrink,
    String? favouriteMusic,
    String? favouriteShow,
    String? favouritePlace,
    String? wakeUpTime,
    String? bedTime,
    String? mealPreferences,
    String? exerciseRoutine,
    String? religiousPractices,
    String? napTime,
    String? preferredLanguage,
    String? communicationStyle,
    String? triggers,
    String? calmingStrategies,
    String? importantPeople,
  }) {
    return PatientProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      trustedDeviceId: trustedDeviceId ?? this.trustedDeviceId,
      lastBiometricLogin: lastBiometricLogin ?? this.lastBiometricLogin,
      hobbies: hobbies ?? this.hobbies,
      favouritePastime: favouritePastime ?? this.favouritePastime,
      indoorOutdoorPref: indoorOutdoorPref ?? this.indoorOutdoorPref,
      favouriteFood: favouriteFood ?? this.favouriteFood,
      favouriteDrink: favouriteDrink ?? this.favouriteDrink,
      favouriteMusic: favouriteMusic ?? this.favouriteMusic,
      favouriteShow: favouriteShow ?? this.favouriteShow,
      favouritePlace: favouritePlace ?? this.favouritePlace,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      bedTime: bedTime ?? this.bedTime,
      mealPreferences: mealPreferences ?? this.mealPreferences,
      exerciseRoutine: exerciseRoutine ?? this.exerciseRoutine,
      religiousPractices: religiousPractices ?? this.religiousPractices,
      napTime: napTime ?? this.napTime,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      triggers: triggers ?? this.triggers,
      calmingStrategies: calmingStrategies ?? this.calmingStrategies,
      importantPeople: importantPeople ?? this.importantPeople,
    );
  }
}
