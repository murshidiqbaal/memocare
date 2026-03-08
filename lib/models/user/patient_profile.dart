class PatientProfile {
  final String id;
  final String? userId; // Adding userId to track the owner

  // Personal
  final String? fullName;
  final String? phoneNumber;
  final String? address;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? profileImageUrl;

  // Emergency & Medical
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? medicalNotes;

  // Hobbies & Interests
  final List<String>? hobbies;
  final String? favouritePastime;
  final String? indoorOutdoorPref;

  // Favourite Things
  final String? favouriteFood;
  final String? favouriteDrink;
  final String? favouriteMusic;
  final String? favouriteShow;
  final String? favouritePlace;

  // Daily Routine
  final String? wakeUpTime;
  final String? bedTime;
  final String? napTime;
  final String? mealPreferences;
  final String? exerciseRoutine;
  final String? religiousPractices;

  // Language & Communication
  final String? preferredLanguage;
  final String? communicationStyle;
  final String? triggers;
  final String? calmingStrategies;
  final String? importantPeople;

  // Meta
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientProfile({
    required this.id,
    this.userId,
    this.fullName,
    this.phoneNumber,
    this.address,
    this.dateOfBirth,
    this.gender,
    this.profileImageUrl,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.medicalNotes,
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
    this.napTime,
    this.mealPreferences,
    this.exerciseRoutine,
    this.religiousPractices,
    this.preferredLanguage,
    this.communicationStyle,
    this.triggers,
    this.calmingStrategies,
    this.importantPeople,
    this.createdAt,
    this.updatedAt,
  });

  // ── fromJson ──────────────────────────────────────────────────────────────

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String?,

      // Personal
      fullName: json['full_name'] as String?,
      phoneNumber: (json['phone_number'] ?? json['phone']) as String?,
      address: json['address'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      profileImageUrl: json['profile_photo_url'] as String?,

      // Emergency & Medical
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      medicalNotes: json['medical_notes'] as String?,

      // Hobbies & Interests
      // Column is TEXT in Supabase → arrives as a comma-separated string.
      // Guard against legacy jsonb lists that may still exist.
      hobbies: _parseHobbies(json['hobbies']),
      favouritePastime: json['favourite_pastime'] as String?,
      indoorOutdoorPref: json['indoor_outdoor_pref'] as String?,

      // Favourite Things
      favouriteFood: json['favourite_food'] as String?,
      favouriteDrink: json['favourite_drink'] as String?,
      favouriteMusic: json['favourite_music'] as String?,
      favouriteShow: json['favourite_show'] as String?,
      favouritePlace: json['favourite_place'] as String?,

      // Daily Routine
      wakeUpTime: json['wake_up_time'] as String?,
      bedTime: json['bed_time'] as String?,
      napTime: json['nap_time'] as String?,
      mealPreferences: json['meal_preferences'] as String?,
      exerciseRoutine: json['exercise_routine'] as String?,
      religiousPractices: json['religious_practices'] as String?,

      // Language & Communication
      preferredLanguage: json['preferred_language'] as String?,
      communicationStyle: json['communication_style'] as String?,
      triggers: json['triggers'] as String?,
      calmingStrategies: json['calming_strategies'] as String?,
      importantPeople: json['important_people'] as String?,

      // Meta
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  // ── toJson ────────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'full_name': fullName,
        'phone': phoneNumber,
        'address': address,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'gender': gender,
        'profile_photo_url': profileImageUrl,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'medical_notes': medicalNotes,
        'hobbies': hobbies?.join(', '),
        'favourite_pastime': favouritePastime,
        'indoor_outdoor_pref': indoorOutdoorPref,
        'favourite_food': favouriteFood,
        'favourite_drink': favouriteDrink,
        'favourite_music': favouriteMusic,
        'favourite_show': favouriteShow,
        'favourite_place': favouritePlace,
        'wake_up_time': wakeUpTime,
        'bed_time': bedTime,
        'nap_time': napTime,
        'meal_preferences': mealPreferences,
        'exercise_routine': exerciseRoutine,
        'religious_practices': religiousPractices,
        'preferred_language': preferredLanguage,
        'communication_style': communicationStyle,
        'triggers': triggers,
        'calming_strategies': calmingStrategies,
        'important_people': importantPeople,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  PatientProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
    String? gender,
    String? profileImageUrl,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? medicalNotes,
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
    String? napTime,
    String? mealPreferences,
    String? exerciseRoutine,
    String? religiousPractices,
    String? preferredLanguage,
    String? communicationStyle,
    String? triggers,
    String? calmingStrategies,
    String? importantPeople,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      medicalNotes: medicalNotes ?? this.medicalNotes,
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
      napTime: napTime ?? this.napTime,
      mealPreferences: mealPreferences ?? this.mealPreferences,
      exerciseRoutine: exerciseRoutine ?? this.exerciseRoutine,
      religiousPractices: religiousPractices ?? this.religiousPractices,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      triggers: triggers ?? this.triggers,
      calmingStrategies: calmingStrategies ?? this.calmingStrategies,
      importantPeople: importantPeople ?? this.importantPeople,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Parses the [hobbies] field from Supabase, which is now a TEXT column.
///
/// Handles three cases safely:
///   • null              → null
///   • CSV string        → "Reading, Music"   → ['Reading', 'Music']
///   • Legacy JSON list  → ["Reading","Music"] → ['Reading', 'Music']
List<String>? _parseHobbies(dynamic value) {
  if (value == null) return null;

  // New format: plain comma-separated string
  if (value is String) {
    if (value.trim().isEmpty) return null;
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // Legacy format: jsonb list (should no longer arrive, but kept as guard)
  if (value is List) {
    return value.map((e) => e.toString().trim()).toList();
  }

  return null;
}
