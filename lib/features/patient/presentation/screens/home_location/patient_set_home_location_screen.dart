// import 'package:dementia_care_app/core/services/location_tracking_service.dart';
// import 'package:dementia_care_app/data/models/patient_home_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:memocare/core/services/location_tracking_service.dart';
import 'package:memocare/data/models/patient_home_location.dart';

// CHANGES MADE:
// 1. Added _hasExistingLocation flag to track if home location is already set
// 2. Renamed _loadCurrentLocation() and created separate _loadPatientHomeLocation()
//    to first check database for existing location
// 3. Modified _onMapTapped() to only allow map interaction if !_hasExistingLocation
// 4. Updated map options to disable dragging when location already exists
// 5. Modified instruction banner to show different message based on location status
// 6. Updated button UI: Shows disabled button + Done button when location exists
// 7. Changed button styling to show grey disabled state when location is already set

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
  bool _hasExistingLocation = false; // NEW: Track if location is already set

  static const double _radiusMeters = 1000;

  @override
  void initState() {
    super.initState();
    _loadPatientHomeLocation(); // CHANGED: Call database check first
  }

  /// CHANGED: New method to load from database first, then fallback to current location
  Future<void> _loadPatientHomeLocation() async {
    try {
      final repo = ref.read(locationRepositoryProvider);
      final existingLocation =
          await repo.getPatientHomeLocation(widget.patientId);

      if (existingLocation != null) {
        // Home location already exists - load it and disable editing
        setState(() {
          _selectedLocation =
              LatLng(existingLocation.latitude, existingLocation.longitude);
          _hasExistingLocation = true; // PREVENTS EDITING
          _isLoading = false;
        });
      } else {
        // No existing location - proceed with current location
        await _loadCurrentLocation();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading home location: $e')),
        );
      }
    }
  }

  /// UNCHANGED: Get current device location
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

  /// CHANGED: Only allow map tapping if no existing location
  void _onMapTapped(TapPosition tapPosition, LatLng position) {
    if (!_hasExistingLocation) {
      setState(() => _selectedLocation = position);
    }
  }

  /// UNCHANGED: Save home location (unchanged logic, but state persists)
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

      final trackingSvc = ref.read(locationTrackingServiceProvider);
      await trackingSvc.startTracking(widget.patientId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Home location saved! This will monitor your safety.'),
          ),
        );
        setState(() => _hasExistingLocation = true); // PREVENT FUTURE EDITS
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
                // CHANGED: Dynamic banner text based on location status
                Container(
                  padding: const EdgeInsets.all(16),
                  color: _hasExistingLocation
                      ? Colors.amber.shade50
                      : Colors.teal.shade50,
                  child: Text(
                    _hasExistingLocation
                        ? 'Home location is already set. It cannot be changed to protect your routine.'
                        : 'Tap on the map to set your home. A 1 KM safe zone will be created around it.',
                    style: TextStyle(
                      fontSize: 18,
                      color: _hasExistingLocation ? Colors.orange : Colors.teal,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // CHANGED: Map drag disabled when location exists
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 14.0,
                      onTap: _onMapTapped,
                      interactionOptions: InteractionOptions(
                        flags: _hasExistingLocation
                            ? InteractiveFlag.all & ~InteractiveFlag.drag
                            : InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.memocare.app',
                        maxZoom: 19,
                      ),
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

                // CHANGED: Different button UI based on location status
                Container(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: _hasExistingLocation
                        ? Column(
                            children: [
                              // Disabled grey button showing status
                              ElevatedButton(
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text(
                                  'HOME LOCATION ALREADY SET',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Done button to exit screen
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text(
                                  'DONE',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ElevatedButton(
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
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

/*
KEY CHANGES SUMMARY:

1. DATABASE LOOKUP ON INIT
   - _loadPatientHomeLocation() now checks database first for existing location
   - If found, loads it and sets _hasExistingLocation = true
   - If not found, falls back to getting current device location

2. PREVENTS EDITING
   - Map taps are ignored when _hasExistingLocation = true
   - Map dragging is disabled via InteractionOptions
   - _onMapTapped() guard clause prevents location changes

3. USER FEEDBACK
   - Instruction banner changes color and message based on status
   - Amber banner with warning when location already exists
   - Teal banner with instructions when location can be set

4. BUTTON STATE
   - Shows "HOME LOCATION ALREADY SET" (disabled grey button) when location exists
   - Shows "DONE" button to exit when location is already set
   - Shows "SAVE HOME LOCATION" when location can still be set

5. SECURITY
   - Once _hasExistingLocation = true, only way to change is database deletion
   - Screen prevents all UI-based modification
   - Protects patient routine from accidental changes
*/
