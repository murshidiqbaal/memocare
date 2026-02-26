import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../providers/safe_zone_provider.dart';

class SafeZonePickerScreen extends ConsumerStatefulWidget {
  final String patientId;
  final double? initialLatitude;
  final double? initialLongitude;
  final int? initialRadiusMeters;
  final String? existingZoneId;
  final String? initialLabel;

  const SafeZonePickerScreen({
    super.key,
    required this.patientId,
    this.initialLatitude,
    this.initialLongitude,
    this.initialRadiusMeters,
    this.existingZoneId,
    this.initialLabel,
  });

  @override
  ConsumerState<SafeZonePickerScreen> createState() =>
      _SafeZonePickerScreenState();
}

class _SafeZonePickerScreenState extends ConsumerState<SafeZonePickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  LatLng? _selectedLocation;
  int _currentRadius = 100;

  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();

    _currentRadius = widget.initialRadiusMeters ?? 100;

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _isLoadingLocation = false;
    } else {
      _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      _showErrorSnackBar('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        _showErrorSnackBar('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      _showErrorSnackBar('Location permissions are permanently denied.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(
        _selectedLocation!,
        16.0,
      ));
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showErrorSnackBar('Unable to determine location');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null) {
      _showErrorSnackBar('Please select a location on the map');
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final success =
        await ref.read(safeZoneControllerProvider.notifier).saveSafeZone(
              patientId: widget.patientId,
              latitude: _selectedLocation!.latitude,
              longitude: _selectedLocation!.longitude,
              radiusMeters: _currentRadius,
              label: widget.initialLabel ?? 'Home',
              existingId: widget.existingZoneId,
            );

    if (success && mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Home Location saved successfully'),
          backgroundColor: Colors.teal,
        ),
      );
      nav.pop(true);
    } else if (mounted) {
      final error = ref.read(safeZoneControllerProvider).error;
      _showErrorSnackBar(error ?? 'Failed to save location');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(safeZoneControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Home Location'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // The Map
          _isLoadingLocation
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.teal))
              : GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ??
                        const LatLng(37.7749, -122.4194), // Default to SF
                    zoom: 16,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  onTap: _onMapTapped,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  compassEnabled: false,
                  markers: _selectedLocation == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('home_location'),
                            position: _selectedLocation!,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueCyan),
                          ),
                        },
                  circles: _selectedLocation == null
                      ? {}
                      : {
                          Circle(
                            circleId: const CircleId('safe_zone_radius'),
                            center: _selectedLocation!,
                            radius: _currentRadius.toDouble(),
                            fillColor: Colors.teal.withOpacity(0.2),
                            strokeColor: Colors.teal,
                            strokeWidth: 2,
                          ),
                        },
                ),

          // Action Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Safe Zone Radius',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${_currentRadius}m'),
                      Expanded(
                        child: Slider(
                          value: _currentRadius.toDouble(),
                          min: 50,
                          max: 500,
                          divisions: 9,
                          activeColor: Colors.teal,
                          onChanged: (value) {
                            setState(() {
                              _currentRadius = value.toInt();
                            });
                          },
                        ),
                      ),
                      const Text('500m'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: state.isLoading || _selectedLocation == null
                        ? null
                        : _saveLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirm Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
