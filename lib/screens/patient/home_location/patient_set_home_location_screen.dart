import 'package:dementia_care_app/data/models/patient_home_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/location_tracking_service.dart';

class PatientSetHomeLocationScreen extends ConsumerStatefulWidget {
  final String patientId;

  const PatientSetHomeLocationScreen({super.key, required this.patientId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PatientSetHomeLocationScreenState();
}

class _PatientSetHomeLocationScreenState
    extends ConsumerState<PatientSetHomeLocationScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  bool _isLoading = true;

  // Radius fixed at 1 km (1000 m) matching original
  static const double _radiusMeters = 1000;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final loc = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = loc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng position) {
    setState(() => _selectedLocation = position);
  }

  Future<void> _saveHomeLocation() async {
    if (_selectedLocation == null) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(locationRepositoryProvider);
      await repo.upsertPatientHomeLocation(PatientHomeLocation(
        patientId: widget.patientId,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        radiusMeters: _radiusMeters.toInt(),
      ));

      // Restart tracking with new home
      final trackingSvc = ref.read(locationTrackingServiceProvider);
      await trackingSvc.startTracking(widget.patientId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Home location saved! This will monitor your safety.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save home: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _selectedLocation ?? const LatLng(37.7749, -122.4194);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Home Location',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Instruction banner
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.teal.shade50,
                  child: const Text(
                    'Tap on the map to set your home. A 1 KM safe zone will be created around it.',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.teal,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Map
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 14.0,
                      onTap: _onMapTapped,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.memocare.app',
                        maxZoom: 19,
                      ),

                      // 1 km safe-zone circle
                      if (_selectedLocation != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _selectedLocation!,
                              radius: _radiusMeters,
                              useRadiusInMeter: true,
                              color: Colors.teal.withOpacity(0.2),
                              borderColor: Colors.teal,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),

                      // Home pin
                      if (_selectedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation!,
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.location_pin,
                                size: 48,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Save button
                Container(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveHomeLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'SAVE HOME LOCATION',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
