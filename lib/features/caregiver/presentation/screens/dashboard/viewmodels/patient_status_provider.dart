// lib/features/caregiver/presentation/screens/dashboard/viewmodels/patient_status_provider.dart

import 'dart:math' as math;

import 'package:memocare/providers/active_patient_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// import 'package:memocare/features/caregiver/providers/caregiver_dashboard_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────
class PatientStatus {
  const PatientStatus({
    required this.isSafe,
    required this.locationName,
    required this.lastActive,
    required this.completedReminders,
    required this.totalReminders,
    required this.patientName,
    this.age,
    this.condition,
    this.phone,
    this.profilePhotoUrl,
  });

  final bool isSafe;
  final String locationName;
  final DateTime lastActive;
  final int completedReminders;
  final int totalReminders;
  final String patientName;
  final int? age;
  final String? condition;
  final String? phone;
  final String? profilePhotoUrl;

  // Pending count derived — no extra DB column needed
  int get pendingReminders => totalReminders - completedReminders;

  // Progress 0.0–1.0
  double get adherenceRatio =>
      totalReminders == 0 ? 0 : completedReminders / totalReminders;

  static PatientStatus get loading => PatientStatus(
        isSafe: true,
        locationName: 'Loading…',
        lastActive: DateTime.now(),
        completedReminders: 0,
        totalReminders: 0,
        patientName: 'Loading…',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Haversine distance in metres
// ─────────────────────────────────────────────────────────────────────────────
double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _rad(double deg) => deg * math.pi / 180;

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final patientStatusProvider =
    FutureProvider.autoDispose<PatientStatus>((ref) async {
  final patientId = ref.watch(activePatientIdProvider);
  if (patientId == null) return PatientStatus.loading;

  final db = Supabase.instance.client;

  // ── 1. Patient row ──────────────────────────────────────────────────────
  // Columns: id, full_name, age, condition, profile_photo_url
  // NOTE: 'phone' lives on caregiver_profiles, NOT patients.
  //       If you have a phone column on patients, add it to the select string.
  final patientRow = await db
      .from('patients')
      .select('full_name, age, condition, profile_photo_url')
      .eq('id', patientId)
      .maybeSingle() as Map<String, dynamic>?;

  final patientName = _str(patientRow, 'full_name') ?? 'Unknown Patient';
  final age = _int(patientRow, 'age');
  final condition = _str(patientRow, 'condition');
  final profilePhotoUrl = _str(patientRow, 'profile_photo_url');

  // ── 2. Latest location ──────────────────────────────────────────────────
  final locRows = await db
      .from('patient_home_locations')
      .select('latitude, longitude, updated_at')
      .eq('patient_id', patientId)
      .order('updated_at', ascending: false)
      .limit(1) as List;

  double? lat, lng;
  DateTime lastActive = DateTime.now();
  String locationName = 'Location unavailable';

  if (locRows.isNotEmpty) {
    final loc = locRows.first as Map<String, dynamic>;
    lat = _dbl(loc, 'latitude');
    lng = _dbl(loc, 'longitude');
    lastActive =
        DateTime.tryParse(_str(loc, 'updated_at') ?? '') ?? DateTime.now();
    if (lat != null && lng != null) {
      locationName = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    }
  }

  // ── 3. Safe zone ────────────────────────────────────────────────────────
  // Columns: home_lat, home_lng, radius
  final szRows = await db
      .from('safe_zones')
      .select('home_lat, home_lng, radius')
      .eq('patient_id', patientId)
      .limit(1) as List;

  bool isSafe = true; // default safe when no zone defined

  if (szRows.isNotEmpty && lat != null && lng != null) {
    final sz = szRows.first as Map<String, dynamic>;
    final homeLat = _dbl(sz, 'home_lat');
    final homeLng = _dbl(sz, 'home_lng');
    final radius = _dbl(sz, 'radius') ?? 200.0;

    if (homeLat != null && homeLng != null) {
      final dist = _haversine(lat, lng, homeLat, homeLng);
      isSafe = dist <= radius;
      locationName = isSafe
          ? 'Near home · $locationName'
          : 'Outside safe zone · $locationName';
    }
  }

  // ── 4. Today's reminders ────────────────────────────────────────────────
  // Columns: id, reminder_time, is_completed
  // Adjust 'is_completed' to your actual column name if different.
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
  final todayEnd =
      DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

  final reminderRows = await db
      .from('reminders')
      .select('id, is_completed')
      .eq('patient_id', patientId)
      .gte('reminder_time', todayStart)
      .lte('reminder_time', todayEnd) as List;

  final total = reminderRows.length;
  final completed = reminderRows
      .where((r) => (r as Map<String, dynamic>)['is_completed'] == true)
      .length;

  return PatientStatus(
    isSafe: isSafe,
    locationName: locationName,
    lastActive: lastActive,
    completedReminders: completed,
    totalReminders: total,
    patientName: patientName,
    age: age,
    condition: condition,
    phone: null, // add patients.phone to select above once column exists
    profilePhotoUrl: profilePhotoUrl,
  );
});

// ── Safe accessors for dynamic map values ─────────────────────────────────────
String? _str(Map<String, dynamic>? m, String k) =>
    m == null ? null : m[k] as String?;

int? _int(Map<String, dynamic>? m, String k) {
  if (m == null) return null;
  final v = m[k];
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double? _dbl(Map<String, dynamic>? m, String k) {
  if (m == null) return null;
  final v = m[k];
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}
