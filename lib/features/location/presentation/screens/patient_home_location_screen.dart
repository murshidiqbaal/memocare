import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:memocare/features/location/providers/safezone_providers.dart';
import 'package:memocare/providers/safe_zone_provider.dart';

/// Patient can drag a map marker and set a radius to request a new home location.
/// The save action submits a caregiver approval request — it does NOT update
/// the safe zone directly.
class PatientHomeLocationScreen extends ConsumerStatefulWidget {
  final String patientId;
  const PatientHomeLocationScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientHomeLocationScreen> createState() =>
      _PatientHomeLocationScreenState();
}

class _PatientHomeLocationScreenState
    extends ConsumerState<PatientHomeLocationScreen> {
  final MapController _mapController = MapController();

  LatLng? _pickedLocation;
  double _radius = 150;
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _pickedLocation = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_pickedLocation!, 16);
      }
    } catch (e) {
      debugPrint('[PatientHomeLocationScreen] Location init error: $e');
    }
  }

  Future<void> _submit() async {
    if (widget.patientId.isEmpty) {
      _showError('Invalid Patient ID. Cannot submit request.');
      return;
    }

    if (_pickedLocation == null) {
      _showError('Please select a location on the map');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final patientId = widget.patientId;

      debugPrint("═══════════════════════════════════════════════");
      debugPrint("📍 SUBMITTING LOCATION REQUEST");
      debugPrint("Patient ID: $patientId");
      debugPrint("Latitude: ${_pickedLocation!.latitude}");
      debugPrint("Longitude: ${_pickedLocation!.longitude}");
      debugPrint("Radius: ${_radius.round()} meters");
      debugPrint("═══════════════════════════════════════════════");

      // Submit request to service
      await ref.read(locationChangeRequestServiceProvider).submitRequest(
            patientId: patientId,
            latitude: _pickedLocation!.latitude,
            longitude: _pickedLocation!.longitude,
            radius: _radius.round(),
          );

      debugPrint("✅ Request submitted successfully!");

      // Refresh request history
      ref.invalidate(patientLocationRequestsProvider(patientId));

      if (mounted) {
        setState(() => _submitted = true);
      }
    } catch (e, stack) {
      debugPrint("❌ LOCATION REQUEST ERROR: $e");
      debugPrintStack(stackTrace: stack);

      if (mounted) {
        _showError('Failed to send request: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Show error snackbar with better UX
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch existing safe zone to seed initial location
    final patientId = widget.patientId;
    final safeZoneAsync = patientId.isEmpty
        ? const AsyncValue.data(null)
        : ref.watch(patientSafeZoneProvider(patientId));

    safeZoneAsync.whenData((zone) {
      if (zone != null && _pickedLocation == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _pickedLocation = LatLng(zone.homeLat, zone.homeLng);
            _radius = zone.radius.toDouble();
          });
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Set Home Location',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _submitted ? _buildSuccessBanner() : _buildPicker(),
    );
  }

  Widget _buildPicker() {
    final initialCenter = _pickedLocation ?? const LatLng(10.85, 76.27);

    return Column(
      children: [
        // ── Map ────────────────────────────────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 16,
                  onTap: (_, latLng) =>
                      setState(() => _pickedLocation = latLng),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.memocare.app',
                  ),
                  if (_pickedLocation != null) ...[
                    CircleLayer(circles: [
                      CircleMarker(
                        point: _pickedLocation!,
                        radius: _radius,
                        useRadiusInMeter: true,
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2,
                      ),
                    ]),
                    MarkerLayer(markers: [
                      Marker(
                        point: _pickedLocation!,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: const Icon(Icons.home_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8)
                      ],
                    ),
                    child: Text(
                      'Tap the map to set home',
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom sheet ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Safe Radius',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _radius,
                      min: 50,
                      max: 500,
                      divisions: 90,
                      activeColor: const Color(0xFF1E3A8A),
                      onChanged: (v) => setState(() => _radius = v),
                    ),
                  ),
                  Container(
                    width: 70,
                    alignment: Alignment.center,
                    child: Text(
                      '${_radius.round()} m',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.amber.shade800, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your caregiver must approve this change.',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: (_pickedLocation == null || _isSubmitting)
                      ? null
                      : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isSubmitting
                        ? 'Sending request…'
                        : 'Request Location Change',
                    style: GoogleFonts.outfit(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessBanner() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded,
                  size: 48, color: Colors.green.shade600),
            ),
            const SizedBox(height: 24),
            Text('Request Sent!',
                style: GoogleFonts.outfit(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Your caregiver will be notified to review and approve your new home location.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 15, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
