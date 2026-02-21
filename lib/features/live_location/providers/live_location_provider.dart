import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../patient_selection/providers/patient_selection_provider.dart';
import '../data/patient_location_model.dart';

// Stream provider that automatically manages the realtime subscription based on selected patient.
final liveLocationStreamProvider =
    StreamProvider.autoDispose<PatientLocation?>((ref) {
  final selectedPatientId = ref.watch(
      patientSelectionProvider.select((state) => state.selectedPatient?.id));

  if (selectedPatientId == null || selectedPatientId.isEmpty) {
    return Stream.value(null); // No patient selected
  }

  final service = LiveLocationService(Supabase.instance.client);
  ref.onDispose(() {
    service.dispose(); // Ensure cleanup when provider is destroyed
  });

  return service.subscribeToPatientLocation(selectedPatientId);
});

class LiveLocationService {
  final SupabaseClient _supabase;
  RealtimeChannel? _channel;
  final StreamController<PatientLocation?> _locationController =
      StreamController<PatientLocation?>.broadcast();

  LiveLocationService(this._supabase);

  /// Subscribes to realtime updates for a specific patient's location
  Stream<PatientLocation?> subscribeToPatientLocation(String patientId) {
    // 1. Fetch the latest location first (initial state)
    _fetchInitialLocation(patientId);

    // 2. Setup Realtime subscription
    _setupRealtimeSubscription(patientId);

    return _locationController.stream;
  }

  Future<void> _fetchInitialLocation(String patientId) async {
    try {
      final response = await _supabase
          .from('patient_locations')
          .select()
          .eq('patient_id', patientId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && !_locationController.isClosed) {
        _locationController.add(PatientLocation.fromJson(response));
      }
    } catch (e) {
      print('Error fetching initial location: $e');
    }
  }

  void _setupRealtimeSubscription(String patientId) {
    // Clean up any existing channel
    _channel?.unsubscribe();

    _channel =
        _supabase.channel('public:patient_locations:patient_id=$patientId');

    _channel!
        .onPostgresChanges(
      event: PostgresChangeEvent.all, // Listen to INSERT, UPDATE, DELETE
      schema: 'public',
      table: 'patient_locations',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'patient_id',
        value: patientId,
      ),
      callback: (payload) {
        if (_locationController.isClosed) return;

        if (payload.eventType == PostgresChangeEvent.delete) {
          // If deleted (unlikely for live tracking, but possible)
          // we could leave the last known or emit null
        } else if (payload.newRecord.isNotEmpty) {
          try {
            final loc = PatientLocation.fromJson(payload.newRecord);
            _locationController.add(loc);
          } catch (e) {
            print('Error parsing location payload: $e');
          }
        }
      },
    )
        .subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.closed &&
          !_locationController.isClosed) {
        // Handle unexpected disconnects (could implement retry logic here)
      }
    });
  }

  void dispose() {
    _channel?.unsubscribe();
    if (!_locationController.isClosed) {
      _locationController.close();
    }
  }
}
