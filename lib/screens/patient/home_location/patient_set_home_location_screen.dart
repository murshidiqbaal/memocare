import 'dart:async';

import 'package:dementia_care_app/data/models/patient_home_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _selectedLocation;
  Set<Circle> _circles = {};
  bool _isLoading = true;

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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _updateCircle(_selectedLocation!);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  void _updateCircle(LatLng location) {
    _circles = {
      Circle(
        circleId: const CircleId('home_radius'),
        center: location,
        radius: 1000, // 1 KM radius
        fillColor: Colors.teal.withOpacity(0.2),
        strokeColor: Colors.teal,
        strokeWidth: 2,
      ),
    };
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _updateCircle(position);
    });
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
        radiusMeters: 1000,
      ));

      // Restart tracking with new home
      final trackingSvc = ref.read(locationTrackingServiceProvider);
      await trackingSvc.startTracking(widget.patientId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Home location saved successfully! This will monitor your safety.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save home: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: _selectedLocation == null
                      ? const Center(child: Text('Waiting for location...'))
                      : GoogleMap(
                          onMapCreated: (GoogleMapController controller) {
                            _controller.complete(controller);
                          },
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation!,
                            zoom: 14.0,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('home'),
                              position: _selectedLocation!,
                            ),
                          },
                          circles: _circles,
                          onTap: _onMapTapped,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveHomeLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('SAVE HOME LOCATION',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
