import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/models/sos_alert.dart';
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
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  double? _distanceInMeters;

  @override
  void initState() {
    super.initState();
    _currentPosition = LatLng(widget.alert.latitude, widget.alert.longitude);
    _updateMarker(_currentPosition!);
    _calculateDistance();
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('patient'),
          position: position,
          infoWindow: InfoWindow(
              title: widget.patientName, snippet: 'Emergency Live Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
  }

  Future<void> _calculateDistance() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (_currentPosition != null) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        setState(() {
          _distanceInMeters = distance;
        });
      }
    } catch (e) {
      debugPrint('Error calculating distance: $e');
    }
  }

  Future<void> _animateCamera(LatLng position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(position));
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
      if (mounted) Navigator.pop(context); // Close map screen
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to stream updates
    ref.listen(liveLocationStreamProvider(widget.alert.patientId),
        (previous, next) {
      next.whenData((locations) {
        if (locations.isNotEmpty) {
          final loc = locations.first;
          final newPos = LatLng(loc.latitude, loc.longitude);
          _updateMarker(newPos);
          _currentPosition = newPos;
          _animateCamera(newPos);
          _calculateDistance(); // Recalculate distance dynamically
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking ${widget.patientName}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: true, // Show caregiver location too
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),

          // Bottom Sheet with Info & Action
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
                          Text(
                            'Distance',
                            style: GoogleFonts.outfit(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _distanceInMeters != null
                                ? '${(_distanceInMeters! / 1000).toStringAsFixed(1)} km away'
                                : 'Locating...',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'MARK AS SAFE / RESOLVE',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
