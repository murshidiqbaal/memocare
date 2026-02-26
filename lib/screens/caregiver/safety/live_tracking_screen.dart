import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

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
  GoogleMapController? _mapController;

  LocationLog? _currentLocation;
  // ignore: unused_field
  SafeZone? _safeZone;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

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
      _circles.add(
        Circle(
          circleId: const CircleId('safe_zone'),
          center: LatLng(zone.latitude, zone.longitude),
          radius: zone.radiusMeters.toDouble(),
          fillColor: Colors.teal.withOpacity(0.1),
          strokeColor: Colors.teal,
          strokeWidth: 2,
        ),
      );
    });
  }

  void _startListening() {
    _service.getLocationStream().listen((log) {
      if (!mounted) return;
      setState(() {
        _currentLocation = log;
        _updateMarker(log);
      });

      // Auto-pan
      _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(log.latitude, log.longitude)));
    });
  }

  void _updateMarker(LocationLog log) {
    _markers.clear();

    // Patient Marker
    _markers.add(Marker(
        markerId: const MarkerId('patient'),
        position: LatLng(log.latitude, log.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            log.isBreach ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
            title: 'Grandpa Joe',
            snippet:
                "Last seen: ${DateFormat('h:mm:ss a').format(log.recordedAt)}")));
  }

  @override
  Widget build(BuildContext context) {
    final isBreach = _currentLocation?.isBreach ?? false;
    final statusColor = isBreach ? Colors.red : Colors.teal;
    final statusText = isBreach ? 'OUTSIDE SAFE ZONE' : 'INSIDE SAFE ZONE';

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
          // Status Banner
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

          // Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(37.422, -122.084),
                zoom: 16,
              ),
              onMapCreated: (c) => _mapController = c,
              markers: _markers,
              circles: _circles,
              myLocationButtonEnabled: false,
            ),
          ),

          // Bottom Info
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
                    backgroundImage: AssetImage(
                        'assets/images/placeholders/elderly_man.jpg'),
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Grandpa Joe',
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
                        // Refocus
                        _mapController?.animateCamera(CameraUpdate.newLatLng(
                            LatLng(_currentLocation!.latitude,
                                _currentLocation!.longitude)));
                      },
                      icon: const Icon(Icons.my_location, color: Colors.teal))
                ],
              ),
            )
        ],
      ),
    );
  }
}
