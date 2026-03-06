class PatientProfile {
  final String id;
  final String userId;

  // Personal Information
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phoneNumber;
  final String? address;
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
  final String? mealPreferences;
  final String? exerciseRoutine;
  final String? religiousPractices;
  final String? napTime;

  // Language & Communication
  final String? preferredLanguage;
  final String? communicationStyle;
  final String? triggers;
  final String? calmingStrategies;
  final String? importantPeople;

  const PatientProfile({
    required this.id,
    required this.userId,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.address,
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

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      phoneNumber: json['phone_number'] as String?,
      address: json['address'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      medicalNotes: json['medical_notes'] as String?,
      hobbies: json['hobbies'] != null
          ? List<String>.from(json['hobbies'] as List)
          : null,
      favouritePastime: json['favourite_pastime'] as String?,
      indoorOutdoorPref: json['indoor_outdoor_pref'] as String?,
      favouriteFood: json['favourite_food'] as String?,
      favouriteDrink: json['favourite_drink'] as String?,
      favouriteMusic: json['favourite_music'] as String?,
      favouriteShow: json['favourite_show'] as String?,
      favouritePlace: json['favourite_place'] as String?,
      wakeUpTime: json['wake_up_time'] as String?,
      bedTime: json['bed_time'] as String?,
      mealPreferences: json['meal_preferences'] as String?,
      exerciseRoutine: json['exercise_routine'] as String?,
      religiousPractices: json['religious_practices'] as String?,
      napTime: json['nap_time'] as String?,
      preferredLanguage: json['preferred_language'] as String?,
      communicationStyle: json['communication_style'] as String?,
      triggers: json['triggers'] as String?,
      calmingStrategies: json['calming_strategies'] as String?,
      importantPeople: json['important_people'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'full_name': fullName,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'gender': gender,
        'phone_number': phoneNumber,
        'address': address,
        'profile_image_url': profileImageUrl,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'medical_notes': medicalNotes,
        'hobbies': hobbies,
        'favourite_pastime': favouritePastime,
        'indoor_outdoor_pref': indoorOutdoorPref,
        'favourite_food': favouriteFood,
        'favourite_drink': favouriteDrink,
        'favourite_music': favouriteMusic,
        'favourite_show': favouriteShow,
        'favourite_place': favouritePlace,
        'wake_up_time': wakeUpTime,
        'bed_time': bedTime,
        'meal_preferences': mealPreferences,
        'exercise_routine': exerciseRoutine,
        'religious_practices': religiousPractices,
        'nap_time': napTime,
        'preferred_language': preferredLanguage,
        'communication_style': communicationStyle,
        'triggers': triggers,
        'calming_strategies': calmingStrategies,
        'important_people': importantPeople,
      };

  PatientProfile copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? address,
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
    String? mealPreferences,
    String? exerciseRoutine,
    String? religiousPractices,
    String? napTime,
    String? preferredLanguage,
    String? communicationStyle,
    String? triggers,
    String? calmingStrategies,
    String? importantPeople,
  }) =>
      PatientProfile(
        id: id,
        userId: userId,
        fullName: fullName ?? this.fullName,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        gender: gender ?? this.gender,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        address: address ?? this.address,
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
