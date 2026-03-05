class PatientProfile {
  final String id;
  final String userId;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final String? medicalNotes;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? photoUrl;
  // Optional fields to add
  final List<String>? hobbies;
  final String? favouriteMusic;
  final String? favouriteShow;
  final String? favouriteFood;
  final String? wakeUpTime;
  final String? bedTime;
  final String? mealPreferences;
  final String? exerciseRoutine;
  final String? religiousPractices;
  final String? preferredLanguage;
  final String? communicationStyle;
  final String? triggers;
  final String? calmingStrategies;
  final String? occupation;
  final String? hometown;
  final String? lifeEvents;
  final String? familyMembers;
  final String? pets;

  PatientProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    this.medicalNotes,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.photoUrl,
    this.hobbies,
    this.favouriteMusic,
    this.favouriteShow,
    this.favouriteFood,
    this.wakeUpTime,
    this.bedTime,
    this.mealPreferences,
    this.exerciseRoutine,
    this.religiousPractices,
    this.preferredLanguage,
    this.communicationStyle,
    this.triggers,
    this.calmingStrategies,
    this.occupation,
    this.hometown,
    this.lifeEvents,
    this.familyMembers,
    this.pets,
  });

  PatientProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? medicalNotes,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? photoUrl,
    List<String>? hobbies,
    String? favouriteMusic,
    String? favouriteShow,
    String? favouriteFood,
    String? wakeUpTime,
    String? bedTime,
    String? mealPreferences,
    String? exerciseRoutine,
    String? religiousPractices,
    String? preferredLanguage,
    String? communicationStyle,
    String? triggers,
    String? calmingStrategies,
    String? occupation,
    String? hometown,
    String? lifeEvents,
    String? familyMembers,
    String? pets,
  }) {
    return PatientProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      photoUrl: photoUrl ?? this.photoUrl,
      hobbies: hobbies ?? this.hobbies,
      favouriteMusic: favouriteMusic ?? this.favouriteMusic,
      favouriteShow: favouriteShow ?? this.favouriteShow,
      favouriteFood: favouriteFood ?? this.favouriteFood,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      bedTime: bedTime ?? this.bedTime,
      mealPreferences: mealPreferences ?? this.mealPreferences,
      exerciseRoutine: exerciseRoutine ?? this.exerciseRoutine,
      religiousPractices: religiousPractices ?? this.religiousPractices,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      triggers: triggers ?? this.triggers,
      calmingStrategies: calmingStrategies ?? this.calmingStrategies,
      occupation: occupation ?? this.occupation,
      hometown: hometown ?? this.hometown,
      lifeEvents: lifeEvents ?? this.lifeEvents,
      familyMembers: familyMembers ?? this.familyMembers,
      pets: pets ?? this.pets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'medical_notes': medicalNotes,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'photo_url': photoUrl,
      'hobbies': hobbies,
      'favourite_music': favouriteMusic,
      'favourite_show': favouriteShow,
      'favourite_food': favouriteFood,
      'wake_up_time': wakeUpTime,
      'bed_time': bedTime,
      'meal_preferences': mealPreferences,
      'exercise_routine': exerciseRoutine,
      'religious_practices': religiousPractices,
      'preferred_language': preferredLanguage,
      'communication_style': communicationStyle,
      'triggers': triggers,
      'calming_strategies': calmingStrategies,
      'occupation': occupation,
      'hometown': hometown,
      'life_events': lifeEvents,
      'family_members': familyMembers,
      'pets': pets,
    };
  }

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String,
      medicalNotes: json['medical_notes'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      hobbies:
          json['hobbies'] != null ? List<String>.from(json['hobbies']) : null,
      favouriteMusic: json['favourite_music'] as String?,
      favouriteShow: json['favourite_show'] as String?,
      favouriteFood: json['favourite_food'] as String?,
      wakeUpTime: json['wake_up_time'] as String?,
      bedTime: json['bed_time'] as String?,
      mealPreferences: json['meal_preferences'] as String?,
      exerciseRoutine: json['exercise_routine'] as String?,
      religiousPractices: json['religious_practices'] as String?,
      preferredLanguage: json['preferred_language'] as String?,
      communicationStyle: json['communication_style'] as String?,
      triggers: json['triggers'] as String?,
      calmingStrategies: json['calming_strategies'] as String?,
      occupation: json['occupation'] as String?,
      hometown: json['hometown'] as String?,
      lifeEvents: json['life_events'] as String?,
      familyMembers: json['family_members'] as String?,
      pets: json['pets'] as String?,
    );
  }
}
