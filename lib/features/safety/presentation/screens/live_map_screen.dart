import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'package:dementia_care_app/data/models/sos_alert.dart';
import '../controllers/sos_controller.dart';

class LiveMapScreen extends ConsumerStatefulWidget {
  final SosAlert alert;
  final String patientName;

  const LiveMapScreen({
    super.key,
    required this.alert,
    required this.patientName,
  });

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  double? _distanceInMeters;

  @override
  void initState() {
    super.initState();
    _currentPosition =
        LatLng(widget.alert.latitude ?? 0.0, widget.alert.longitude ?? 0.0);
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (_currentPosition != null && mounted) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        setState(() => _distanceInMeters = distance);
      }
    } catch (e) {
      debugPrint('Error calculating distance: $e');
    }
  }

  Future<void> _resolveSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Emergency?'),
        content: const Text(
            'This will mark the patient as safe and stop live tracking.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark as Safe'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(sosControllerProvider.notifier)
          .resolveSos(widget.alert.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(liveLocationStreamProvider(widget.alert.patientId),
        (previous, next) {
      next.whenData((locations) {
        if (locations.isNotEmpty) {
          final loc = locations.first;
          final newPos = LatLng(loc.latitude, loc.longitude);
          setState(() => _currentPosition = newPos);
          _mapController.move(newPos, _mapController.camera.zoom);
          _calculateDistance();
        }
      });
    });

    final pos = _currentPosition ??
        LatLng(widget.alert.latitude ?? 0.0, widget.alert.longitude ?? 0.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking ${widget.patientName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: pos, initialZoom: 15),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.memocare.app',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: pos,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Bottom info card
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Distance',
                              style: GoogleFonts.outfit(
                                  color: Colors.grey, fontSize: 12)),
                          Text(
                            _distanceInMeters != null
                                ? '${(_distanceInMeters! / 1000).toStringAsFixed(1)} km away'
                                : 'Locating...',
                            style: GoogleFonts.outfit(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.red),
                            ),
                            const SizedBox(width: 8),
                            Text('LIVE',
                                style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _resolveSos,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('MARK AS SAFE / RESOLVE',
                          style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.bold)),
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
