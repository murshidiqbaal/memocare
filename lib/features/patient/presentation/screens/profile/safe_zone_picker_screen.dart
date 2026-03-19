import 'package:memocare/providers/safe_zone_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// import '../../../providers/safe_zone_provider.dart';

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
  final MapController _mapController = MapController();

  LatLng? _selectedLocation;
  // Fixed radius at 1 km (1000m) for safety standards
  static const int _currentRadius = 1000;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();

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
      final loc = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = loc;
        _isLoadingLocation = false;
      });
      _mapController.move(loc, 16.0);
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

  void _onMapTapped(TapPosition tapPosition, LatLng location) {
    setState(() => _selectedLocation = location);
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
              homeLat: _selectedLocation!.latitude,
              homeLng: _selectedLocation!.longitude,
              radius: _currentRadius.toDouble(),
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
    // Default fallback center (San Francisco)
    final center = _selectedLocation ?? const LatLng(37.7749, -122.4194);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Home Location'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────────
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator(color: Colors.teal))
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16.0,
                onTap: _onMapTapped,
              ),
              children: [
                // OSM tile layer — free, no API key
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.memocare.app',
                  maxZoom: 19,
                ),

                // Safe zone circle
                if (_selectedLocation != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _selectedLocation!,
                        radius: _currentRadius.toDouble(),
                        useRadiusInMeter: true,
                        color: Colors.teal.withOpacity(0.2),
                        borderColor: Colors.teal,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),

                // Pin marker
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

          // ── Bottom action panel ─────────────────────────────────────────
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
                    'Home Safe Zone',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A 1 km (1000m) safety zone will be created around your home to monitor your safety.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                            'Confirm Home Location',
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
