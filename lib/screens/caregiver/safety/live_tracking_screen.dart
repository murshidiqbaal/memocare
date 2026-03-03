import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/models/location_log.dart';
import '../../../../data/models/safe_zone.dart';
import 'safe_zone_setup_screen.dart';
import 'viewmodels/safety_viewmodel.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  final MockSafetyService _service = MockSafetyService();
  final MapController _mapController = MapController();

  LocationLog? _currentLocation;
  SafeZone? _safeZone;
  LatLng? _patientPosition;

  @override
  void initState() {
    super.initState();
    _loadZone();
    _startListening();
  }

  Future<void> _loadZone() async {
    final zone = await _service.getActiveZone();
    setState(() {
      _safeZone = zone;
    });
  }

  void _startListening() {
    _service.getLocationStream().listen((log) {
      if (!mounted) return;
      final pos = LatLng(log.latitude, log.longitude);
      setState(() {
        _currentLocation = log;
        _patientPosition = pos;
      });
      // Auto-pan camera to new position
      _mapController.move(pos, _mapController.camera.zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBreach = _currentLocation?.isBreach ?? false;
    final statusColor = isBreach ? Colors.red : Colors.teal;
    final statusText = isBreach ? 'OUTSIDE SAFE ZONE' : 'INSIDE SAFE ZONE';

    // Default map center
    final center = _patientPosition ?? const LatLng(37.422, -122.084);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SafeZoneSetupScreen()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // ── Status banner ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: statusColor,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isBreach ? Icons.warning_amber_rounded : Icons.shield,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  )
                ],
              ),
            ),
          ),

          // ── Map ────────────────────────────────────────────────────────
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.memocare.app',
                  maxZoom: 19,
                ),

                // Safe zone circle
                if (_safeZone != null &&
                    _safeZone!.centerLatitude != null &&
                    _safeZone!.centerLongitude != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(
                          _safeZone!.centerLatitude!,
                          _safeZone!.centerLongitude!,
                        ),
                        radius: _safeZone!.radiusMeters.toDouble(),
                        useRadiusInMeter: true,
                        color: Colors.teal.withOpacity(0.1),
                        borderColor: Colors.teal,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),

                // Patient marker
                if (_patientPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _patientPosition!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBreach ? Colors.red : Colors.teal,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Bottom info bar ────────────────────────────────────────────
          if (_currentLocation != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Patient',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        "Updated ${DateFormat('h:mm:ss a').format(_currentLocation!.recordedAt)}",
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      if (_patientPosition != null) {
                        _mapController.move(
                            _patientPosition!, _mapController.camera.zoom);
                      }
                    },
                    icon: const Icon(Icons.my_location, color: Colors.teal),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }
}
