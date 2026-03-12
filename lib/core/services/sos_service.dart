import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memocare/providers/service_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/uuid_validator.dart';

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
      if (!isValidUuid(patientId)) {
        throw Exception('Invalid patient ID');
      }

      // Fetch linked caregivers to insert individual SOS alerts per caregiver
      final links = await _supabase
          .from('caregiver_patient_links')
          .select('caregiver_id')
          .eq('patient_id', patientId);

      List<Map<String, dynamic>> payloads = [];

      final validCaregivers = links
          .map((l) => l['caregiver_id'] as String?)
          .where(isValidUuid)
          .toList();

      if (validCaregivers.isEmpty) {
        throw Exception('Invalid caregiver ID');
      }

      for (var caregiverId in validCaregivers) {
        payloads.add({
          'patient_id': patientId,
          'caregiver_id': caregiverId,
          'location_lat': lat,
          'location_lng': lng,
          'status': 'active',
        });
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

      // If we don't have a valid patient ID, we shouldn't even queue it.
      if (!isValidUuid(patientId)) return;

      List<Map<String, dynamic>> fallbackPayloads = [
        {
          'patient_id': patientId,
          'caregiver_id':
              null, // Need to make sure this doesn't break later sync
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
        .from('sos_messages')
        .update({'status': newStatus}).eq('id', alertId);
  }

  Future<void> _processInsert(List<Map<String, dynamic>> payloads) async {
    await _supabase.from('sos_messages').insert(payloads);
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
          final patientId = sosData['patient_id'] as String?;
          if (!isValidUuid(patientId)) continue; // Discard invalid offline data

          // Refetch caregiver links if possible to map out properly on reconnect
          final links = await _supabase
              .from('caregiver_patient_links')
              .select('caregiver_id')
              .eq('patient_id', patientId!);

          final validCaregivers = links
              .map((l) => l['caregiver_id'] as String?)
              .where(isValidUuid)
              .toList();

          if (validCaregivers.isEmpty) continue; // Still no valid caregiver

          List<Map<String, dynamic>> payloads = [];
          for (var cid in validCaregivers) {
            payloads.add({
              'patient_id': patientId,
              'caregiver_id': cid,
              'location_lat': sosData['location_lat'],
              'location_lng': sosData['location_lng'],
              'status': sosData['status'] ?? 'active',
            });
          }

          if (payloads.isNotEmpty) {
            await _processInsert(payloads);
          }
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
