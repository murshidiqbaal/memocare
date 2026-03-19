import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SafeZoneSetupScreen extends ConsumerStatefulWidget {
  const SafeZoneSetupScreen({super.key});

  @override
  ConsumerState<SafeZoneSetupScreen> createState() =>
      _SafeZoneSetupScreenState();
}

class _SafeZoneSetupScreenState extends ConsumerState<SafeZoneSetupScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(37.422, -122.084); // Default, replaced by GPS
  double _radius = 100; // meters
  bool _isLoading = false;
  String _label = 'Home'; // Default label for the safe zone

  // ── Map callbacks ──────────────────────────────────────────────────────────

  void _onMapTap(TapPosition tapPosition, LatLng tappedPos) {
    setState(() => _center = tappedPos);
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _saveSafeZone() async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save a safe zone.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final zoneData = {
        'user_id': currentUser.id,
        'patient_id': currentUser.id,
        'label': _label,
        'center_latitude': _center.latitude,
        'center_longitude': _center.longitude,
        'radius_meters': _radius.toInt(),
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('patient_home_locations')
          .upsert(zoneData, onConflict: 'user_id, label');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Home location saved successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.pop(context);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        final message = e.code == '42501'
            ? 'Permission denied. Please contact support.'
            : 'Failed to save safe zone.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      debugPrint('Supabase error saving safe zone: ${e.message}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Home Location'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Map ────────────────────────────────────────────────────────
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 16,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.memocare.app',
                  maxZoom: 19,
                ),

                // Safe zone circle
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _center,
                      radius: _radius,
                      useRadiusInMeter: true,
                      color: Colors.teal.withOpacity(0.2),
                      borderColor: Colors.teal,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

                // Draggable center pin (flutter_map Marker with drag via map tap)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _center,
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          // flutter_map doesn't support drag natively on markers;
                          // tapping the map moves the pin (see onTap above).
                        },
                        child: Tooltip(
                          message: _label,
                          child: const Icon(
                            Icons.location_pin,
                            size: 48,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Controls panel ─────────────────────────────────────────────
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
                // Location Label
                const Text(
                  'Location Label',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _label,
                  decoration: InputDecoration(
                    hintText: 'e.g. Home, Clinic, School',
                    prefixIcon:
                        const Icon(Icons.label_outline, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _label = val.trim().isEmpty ? 'Home' : val.trim();
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Radius Slider
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
                        onChanged: (v) => setState(() => _radius = v),
                      ),
                    ),
                    Text(
                      '${_radius.toInt()} m',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Tap map to set center',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveSafeZone,
                    icon: _isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.home_outlined, color: Colors.white),
                    label: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save as Home Location',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
