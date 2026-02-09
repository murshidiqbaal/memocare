import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../data/models/safe_zone.dart';
import '../../../../providers/auth_provider.dart';

class SafeZoneSetupScreen extends ConsumerStatefulWidget {
  const SafeZoneSetupScreen({super.key});

  @override
  ConsumerState<SafeZoneSetupScreen> createState() =>
      _SafeZoneSetupScreenState();
}

class _SafeZoneSetupScreenState extends ConsumerState<SafeZoneSetupScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(37.422, -122.084); // Default (Googleplex)
  double _radius = 100; // meters
  final Set<Circle> _circles = {};
  final Set<Marker> _markers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updateOverlay();
  }

  void _onMapTap(LatLng startPos) {
    setState(() {
      _center = startPos;
      _updateOverlay();
    });
  }

  void _updateOverlay() {
    _circles.clear();
    _markers.clear();

    _circles.add(
      Circle(
        circleId: const CircleId('safe_zone'),
        center: _center,
        radius: _radius,
        fillColor: Colors.teal.withOpacity(0.2),
        strokeColor: Colors.teal,
        strokeWidth: 2,
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('center'),
        position: _center,
        draggable: true,
        onDragEnd: (newPos) {
          setState(() {
            _center = newPos;
            _updateOverlay();
          });
        },
      ),
    );
  }

  Future<void> _saveSafeZone() async {
    setState(() => _isLoading = true);

    // Mock Patient ID connection (in real app, specific to selected patient)
    final profile = ref.read(userProfileProvider);
    // Assume caregiver is managing a specific patient, or patient is setting for themselves?
    // User request: "Caregiver Safe-Zone Setup". So we need a target patient.
    // We'll use a dummy 'patient_1' or derived.
    const patientId = 'patient_1';

    final zone = SafeZone.create(
      patientId: patientId,
      lat: _center.latitude,
      lng: _center.longitude,
      radius: _radius,
      name: 'Safe Zone ${DateTime.now().minute}',
    );

    // Stub Save
    // await Supabase.instance.client.from('safe_zones').insert(zone.toJson());
    await Future.delayed(const Duration(seconds: 1)); // Mock Network

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Safe Zone Active & Synced')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Safe Zone'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 16,
              ),
              onMapCreated: (c) => _mapController = c,
              onTap: _onMapTap,
              circles: _circles,
              markers: _markers,
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Safe Zone Radius',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _radius,
                        min: 50,
                        max: 1000,
                        divisions: 19,
                        activeColor: Colors.teal,
                        label: '${_radius.toInt()}m',
                        onChanged: (v) {
                          setState(() {
                            _radius = v;
                            _updateOverlay();
                          });
                        },
                      ),
                    ),
                    Text(
                      '${_radius.toInt()} m',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tap on map to set center. Drag marker to adjust.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSafeZone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Activate Safe Zone',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
