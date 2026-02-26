import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/service_providers.dart';

final sosServiceProvider = Provider<SosService>((ref) {
  return SosService(ref.watch(supabaseClientProvider));
});

class SosService {
  final SupabaseClient _supabase;
  static const _offlineQueueKey = 'offline_sos_queue';

  SosService(this._supabase) {
    _syncOfflineQueue();
  }

  Future<void> triggerSOS({required String patientId}) async {
    Position? position;
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.always ||
          hasPermission == LocationPermission.whileInUse) {
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
      }
    } catch (_) {}

    final lat = position?.latitude;
    final lng = position?.longitude;

    try {
      // Fetch linked caregivers to insert individual SOS alerts per caregiver
      final links = await _supabase
          .from('caregiver_patient_links')
          .select('caregiver_id')
          .eq('patient_id', patientId);

      List<Map<String, dynamic>> payloads = [];

      if (links.isEmpty) {
        // Even if no specific caregiver is linked, we log the alert for the overall system or future caregivers
        payloads.add({
          'patient_id': patientId,
          'caregiver_id': null,
          'location_lat': lat,
          'location_lng': lng,
          'status': 'active',
        });
      } else {
        sandboxPayloads(links, patientId, lat, lng, payloads);
      }

      await _processInsert(payloads);

      // Invoke Email Edge Function
      await _supabase.functions.invoke(
        'send-sos-email',
        body: {'patient_id': patientId},
      );

      _syncOfflineQueue();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to upload SOS. Queueing offline. Error: $e');
      }

      List<Map<String, dynamic>> fallbackPayloads = [
        {
          'patient_id': patientId,
          'caregiver_id':
              null, // We queue a general one when offline since we failed to fetch links
          'location_lat': lat,
          'location_lng': lng,
          'status': 'active',
        }
      ];
      await _queueOfflineSOS(fallbackPayloads);
    }
  }

  void sandboxPayloads(List<dynamic> links, String patientId, double? lat,
      double? lng, List<Map<String, dynamic>> payloads) {
    for (var link in links) {
      payloads.add({
        'patient_id': patientId,
        'caregiver_id': link['caregiver_id'],
        'location_lat': lat,
        'location_lng': lng,
        'status': 'active',
      });
    }
  }

  Future<void> updateSosStatus(String alertId, String newStatus) async {
    await _supabase
        .from('sos_alerts')
        .update({'status': newStatus}).eq('id', alertId);
  }

  Future<void> _processInsert(List<Map<String, dynamic>> payloads) async {
    await _supabase.from('sos_alerts').insert(payloads);
  }

  Future<void> _queueOfflineSOS(List<Map<String, dynamic>> payloads) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList(_offlineQueueKey) ?? [];
      for (var p in payloads) {
        queue.add(jsonEncode(p));
      }
      await prefs.setStringList(_offlineQueueKey, queue);
    } catch (e) {
      if (kDebugMode) print('Failed to write to SharedPreferences: $e');
    }
  }

  Future<void> _syncOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? queue = prefs.getStringList(_offlineQueueKey);

      if (queue == null || queue.isEmpty) return;

      final List<String> remainingQueue = [];
      for (final encoded in queue) {
        try {
          final sosData = jsonDecode(encoded) as Map<String, dynamic>;
          // Refetch caregiver links if possible to map out properly on reconnect, or just push general
          await _processInsert([sosData]);
        } catch (e) {
          remainingQueue.add(encoded);
        }
      }

      if (remainingQueue.isEmpty) {
        await prefs.remove(_offlineQueueKey);
      } else {
        await prefs.setStringList(_offlineQueueKey, remainingQueue);
      }
    } catch (e) {
      if (kDebugMode) print('Offline SOS sync failed: $e');
    }
  }
}
