import 'dart:async';

import 'package:memocare/features/live_location/providers/live_location_provider.dart';
import 'package:memocare/features/location/services/safezone_service.dart';
import 'package:memocare/providers/active_patient_provider.dart';
import 'package:memocare/providers/safe_zone_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

/// Caregiver's full-screen map showing:
///  • Patient's live location (real-time, from existing LiveLocationService)
///  • Home location marker
///  • Blue safe zone circle
///  • OUTSIDE / INSIDE status chip
class CaregiverPatientMapScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;

  const CaregiverPatientMapScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<CaregiverPatientMapScreen> createState() =>
      _CaregiverPatientMapScreenState();
}

class _CaregiverPatientMapScreenState
    extends ConsumerState<CaregiverPatientMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _followPatient = true;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Override the active patient to this screen's specific patientId
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(activePatientIdProvider.notifier)
          .setActivePatient(widget.patientId);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(liveLocationStreamProvider);
    final safeZoneAsync = ref.watch(patientSafeZoneProvider(widget.patientId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.patientName,
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600, fontSize: 16)),
            Text('Live Tracking',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          locationAsync.whenOrNull(
                data: (loc) {
                  if (loc == null) return null;
                  return safeZoneAsync.whenOrNull(
                    data: (zone) {
                      if (zone == null) return null;
                      final dist = SafeZoneService.calculateDistance(
                        loc.latitude,
                        loc.longitude,
                        zone.latitude,
                        zone.longitude,
                      );
                      final isOutside = dist > zone.radiusMeters;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isOutside
                                  ? Colors.red.shade100
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOutside ? '⚠️ OUTSIDE' : '✅ INSIDE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isOutside
                                    ? Colors.red.shade800
                                    : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────────
          locationAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.teal)),
            error: (e, _) => Center(
                child: Text('Location unavailable',
                    style: GoogleFonts.outfit(color: Colors.white))),
            data: (location) {
              if (location == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_searching,
                          color: Colors.grey, size: 48),
                      const SizedBox(height: 12),
                      Text('Waiting for patient location…',
                          style: GoogleFonts.outfit(color: Colors.grey)),
                    ],
                  ),
                );
              }

              final patientLatLng =
                  LatLng(location.latitude, location.longitude);

              if (_followPatient) {
                Future.microtask(() {
                  try {
                    _mapController.move(patientLatLng, 16.5);
                  } catch (_) {}
                });
              }

              return safeZoneAsync.when(
                loading: () => _buildMap(
                    patientLatLng: patientLatLng,
                    homeLatLng: null,
                    radiusMeters: 0),
                error: (_, __) => _buildMap(
                    patientLatLng: patientLatLng,
                    homeLatLng: null,
                    radiusMeters: 0),
                data: (zone) => _buildMap(
                  patientLatLng: patientLatLng,
                  homeLatLng: zone != null
                      ? LatLng(zone.latitude, zone.longitude)
                      : null,
                  radiusMeters: zone?.radiusMeters.toDouble() ?? 0,
                ),
              );
            },
          ),

          // ── Follow toggle ────────────────────────────────────────────────
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'caregiverMapFollowFab',
              backgroundColor: _followPatient ? Colors.teal : Colors.white,
              child: Icon(
                _followPatient ? Icons.my_location : Icons.location_searching,
                color: _followPatient ? Colors.white : Colors.teal,
              ),
              onPressed: () => setState(() => _followPatient = !_followPatient),
            ),
          ),

          // ── LIVE badge ───────────────────────────────────────────────────
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6)
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(Colors.green.shade300,
                            Colors.green.shade700, _pulseController.value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('LIVE',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black87)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap({
    required LatLng patientLatLng,
    required LatLng? homeLatLng,
    required double radiusMeters,
  }) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: patientLatLng,
        initialZoom: 16.5,
        onPositionChanged: (_, hasGesture) {
          if (hasGesture && _followPatient) {
            setState(() => _followPatient = false);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.memocare.app',
          maxZoom: 19,
        ),

        // Safe zone circle
        if (homeLatLng != null && radiusMeters > 0)
          CircleLayer(circles: [
            CircleMarker(
              point: homeLatLng,
              radius: radiusMeters,
              useRadiusInMeter: true,
              color: Colors.blue.withValues(alpha: 0.12),
              borderColor: Colors.blue.shade400,
              borderStrokeWidth: 2.5,
            ),
          ]),

        MarkerLayer(markers: [
          // Home marker
          if (homeLatLng != null)
            Marker(
              point: homeLatLng,
              width: 40,
              height: 40,
              child: Tooltip(
                message: 'Home',
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: const Icon(Icons.home_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),

          // Patient live marker
          Marker(
            point: patientLatLng,
            width: 48,
            height: 48,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) => Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.08),
                child: child,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.teal.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3))
                  ],
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}
