import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/voice_query.dart';
import '../models/caregiver_patient_link.dart';
import '../models/dashboard_stats.dart';
import '../models/reminder.dart';

/// Dashboard Repository
/// Handles data aggregation for caregiver dashboard
class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  /// Get all patients linked to a caregiver
  Future<List<CaregiverPatientLink>> getLinkedPatients(
      String caregiverId) async {
    try {
      // Fetch from Supabase
      final data = await _supabase.from('caregiver_patient_links').select('''
            id,
            caregiver_id,
            patient_id,
            linked_at,
            profiles!patient_id (
              full_name,
              avatar_url
            )
          ''').eq('caregiver_id', caregiverId);

      final links = <CaregiverPatientLink>[];

      for (var item in data) {
        final profile = item['profiles'] as Map<String, dynamic>?;
        final link = CaregiverPatientLink(
          id: item['id'],
          caregiverId: item['caregiver_id'],
          patientId: item['patient_id'],
          patientName: profile?['full_name'] ?? 'Unknown Patient',
          // patientPhotoUrl not in model but passed in constructor?
          // Wait, CaregiverPatientLink model I saw earlier did NOT have patientPhotoUrl.
          // Let me check the model again in thought.
          // The model has: id, caregiverId, patientId, linkedAt, patientEmail, caregiverEmail, patientName, caregiverName.
          // It does NOT have patientPhotoUrl.
          // So I should remove patientPhotoUrl key from older code if it existed, or add it to model.
          // The previous DashboardRepository code was:
          // patientPhotoUrl: profile?['avatar_url'],
          // relationship: item['relationship'],
          // isPrimary: item['is_primary'] ?? false,
          // createdAt: DateTime.parse(item['created_at']),

          // I must match the NEW model constructor.
          linkedAt: DateTime.parse(item['linked_at']),
        );

        links.add(link);
      }

      return links;
    } catch (e) {
      print('Error fetching linked patients: $e');
      return [];
    }
  }

  /// Get dashboard statistics for a patient
  Future<DashboardStats> getDashboardStats(String patientId) async {
    try {
      // Get today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Fetch reminder stats
      final reminders = await _supabase
          .from('reminders')
          .select()
          .eq('patient_id', patientId)
          .gte('remind_at', todayStart.toIso8601String())
          .lt('remind_at', todayEnd.toIso8601String());

      int completed = 0;
      int pending = 0;
      int missed = 0;

      for (var r in reminders) {
        final status = r['status'] as String;
        if (status == 'completed') {
          completed++;
        } else if (status == 'pending') {
          if (DateTime.parse(r['remind_at']).isBefore(now)) {
            missed++;
          } else {
            pending++;
          }
        } else if (status == 'missed') {
          missed++;
        }
      }

      final total = completed + pending + missed;
      final adherence = total > 0 ? (completed / total) * 100 : 0.0;

      // Fetch memory & people cards count
      final memoryCards = await _supabase
          .from('memory_cards')
          .select()
          .eq('patient_id', patientId);

      final peopleCards = await _supabase
          .from('people_cards')
          .select()
          .eq('patient_id', patientId);

      // Fetch last voice interaction
      final voiceQueries = await _supabase
          .from('voice_queries')
          .select('created_at')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .limit(1);

      DateTime? lastVoiceInteraction;
      if (voiceQueries.isNotEmpty) {
        lastVoiceInteraction = DateTime.parse(voiceQueries.first['created_at']);
      }

      // TODO: Fetch safe zone status from location_logs
      // For now, using mock data
      const isInSafeZone = true;
      const safeZoneBreaches = 0;

      // TODO: Fetch journal entries
      // For now, using mock data
      final lastJournalEntry = now.subtract(const Duration(days: 2));

      // TODO: Fetch games played
      const gamesPlayed = 5;

      // Calculate memory journal consistency (mock)
      const journalConsistency = 0.7;

      return DashboardStats(
        remindersCompleted: completed,
        remindersPending: pending,
        remindersMissed: missed,
        adherencePercentage: adherence,
        memoryCardsCount: memoryCards.length,
        peopleCardsCount: peopleCards.length,
        lastJournalEntry: lastJournalEntry,
        lastVoiceInteraction: lastVoiceInteraction,
        isInSafeZone: isInSafeZone,
        safeZoneBreachesThisWeek: safeZoneBreaches,
        lastLocationUpdate: now.subtract(const Duration(minutes: 15)),
        gamesPlayedThisWeek: gamesPlayed,
        memoryJournalConsistency: journalConsistency,
        unreadAlerts: missed + safeZoneBreaches,
      );
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return const DashboardStats();
    }
  }

  /// Get recent voice interactions
  Future<List<VoiceQuery>> getRecentVoiceInteractions(String patientId,
      {int limit = 5}) async {
    try {
      final data = await _supabase
          .from('voice_queries')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .limit(limit);

      return data.map((json) => VoiceQuery.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching voice interactions: $e');
      return [];
    }
  }

  /// Get next upcoming reminder
  Future<Reminder?> getNextReminder(String patientId) async {
    try {
      final now = DateTime.now();
      final data = await _supabase
          .from('reminders')
          .select()
          .eq('patient_id', patientId)
          .eq('status', 'pending')
          .gte('remind_at', now.toIso8601String())
          .order('remind_at', ascending: true)
          .limit(1);

      if (data.isEmpty) return null;
      return Reminder.fromJson(data.first);
    } catch (e) {
      print('Error fetching next reminder: $e');
      return null;
    }
  }

  /// Sync dashboard data
  Future<void> syncDashboard(String caregiverId) async {
    await getLinkedPatients(caregiverId);
  }
}
