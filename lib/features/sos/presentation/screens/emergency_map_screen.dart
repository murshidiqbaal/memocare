import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/models/sos_message.dart';
import '../../../../data/models/safe_zone.dart';
import '../../data/repositories/sos_system_repository.dart';
import '../../../../data/repositories/safe_zone_repository.dart';

final liveLocationStreamProvider =
    StreamProvider.family.autoDispose((ref, String patientId) {
  final repo = ref.watch(sosSystemRepositoryProvider);
  return repo.streamPatientLocation(patientId);
});

final safeZoneFutureProvider =
    FutureProvider.family.autoDispose((ref, String patientId) {
  final repo = ref.watch(safeZoneRepositoryProvider);
  return repo.getPatientSafeZone(patientId);
});

class EmergencyMapScreen extends ConsumerStatefulWidget {
  final SosMessage alert;

  const EmergencyMapScreen({super.key, required this.alert});

  @override
  ConsumerState<EmergencyMapScreen> createState() => _EmergencyMapScreenState();
}

class _EmergencyMapScreenState extends ConsumerState<EmergencyMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPatientLocation;

  @override
  Widget build(BuildContext context) {
    final safeZoneAsync =
        ref.watch(safeZoneFutureProvider(widget.alert.patientId));
    final liveLocAsync =
        ref.watch(liveLocationStreamProvider(widget.alert.patientId));

    // Fallback to SOS trigger location if live location isn't available yet
    final initialPos =
        LatLng(widget.alert.locationLat, widget.alert.locationLng);

    // Process Safe Zone
    List<CircleMarker> circles = [];
    if (safeZoneAsync.value != null) {
      final sz = safeZoneAsync.value as SafeZone;
      circles.add(
        CircleMarker(
          point: LatLng(sz.latitude, sz.longitude),
          radius: sz.radiusMeters.toDouble(),
          useRadiusInMeter: true,
          color: Colors.blue.withValues(alpha: 0.2),
          borderColor: Colors.blue.shade800,
          borderStrokeWidth: 2,
        ),
      );
    }

    // Process Live Location Stream
    List<Marker> markers = [];

    // Static SOS Trigger Marker
    markers.add(
      Marker(
        point: initialPos,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.orange, size: 40),
      ),
    );

    // Live Patient Location Marker
    if (liveLocAsync.value != null) {
      final loc = liveLocAsync.value!;
      _currentPatientLocation = LatLng(loc.lat, loc.lng);
      markers.add(
        Marker(
          point: _currentPatientLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );

      // Auto-pan camera
      _panToLocation(_currentPatientLocation!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Map Tracker',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade900,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialPos,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.memocare.app',
              ),
              CircleLayer(circles: circles),
              MarkerLayer(markers: markers),
            ],
          ),

          if (liveLocAsync.isLoading)
            const Positioned(
              top: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Connecting to live GPS...'),
                    ],
                  ),
                ),
              ),
            )
          else
            Positioned(
              bottom: 30,
              right: 16,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.red),
                onPressed: () {
                  if (_currentPatientLocation != null) {
                    _panToLocation(_currentPatientLocation!);
                  } else {
                    _panToLocation(initialPos);
                  }
                },
              ),
            ),

          // Floating Info Card
          Positioned(
            bottom: 30, left: 16, right: 80, // give FAB room
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Patient: ${widget.alert.patientId.substring(0, 6)}...',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.warning, size: 20, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.alert.note ?? 'Emergency SOS',
                            style: const TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _panToLocation(LatLng target) {
    _mapController.move(target, 17.0);
  }
}
