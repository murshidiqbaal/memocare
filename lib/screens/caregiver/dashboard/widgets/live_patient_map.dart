import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../data/models/patient_live_location.dart';
import '../../../../providers/location_providers.dart';

/// LivePatientMap Widget
/// Performance-optimized realtime tracking for Caregiver Dashboard.
class LivePatientMap extends ConsumerStatefulWidget {
  final String patientId;
  final double height;

  const LivePatientMap({
    super.key,
    required this.patientId,
    this.height = 240,
  });

  @override
  ConsumerState<LivePatientMap> createState() => _LivePatientMapState();
}

class _LivePatientMapState extends ConsumerState<LivePatientMap>
    with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();

  // Local state to avoid rebuilding GoogleMap widget for every marker update
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  bool _isFirstLocation = true;
  bool _followMode = true;

  @override
  Widget build(BuildContext context) {
    // Listen to location updates instead of watching to prevent full build cycles
    ref.listen<AsyncValue<PatientLiveLocation?>>(
      patientLiveLocationProvider(widget.patientId),
      (previous, next) {
        next.whenData((location) {
          if (location != null) {
            _updateLocation(location);
          }
        });
      },
    );

    final initialLocationAsync =
        ref.watch(patientLiveLocationProvider(widget.patientId));

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: initialLocationAsync.when(
        data: (location) {
          if (location == null && _currentPosition == null) {
            return _buildEmptyState();
          }

          // Use internal state if available, otherwise init from first data
          final pos = _currentPosition ??
              LatLng(location!.latitude, location.longitude);

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: pos, zoom: 15),
                onMapCreated: (controller) {
                  if (!_controller.isCompleted) {
                    _controller.complete(controller);
                  }
                },
                onCameraMoveStarted: () {
                  if (_followMode) setState(() => _followMode = false);
                },
                markers: _markers.isEmpty ? _createMarkers(pos) : _markers,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                indoorViewEnabled: false,
                trafficEnabled: false,
                liteModeEnabled: false,
              ),

              // Map Overlays
              Positioned(
                top: 12,
                left: 12,
                child: _buildLocationBadge(location),
              ),

              Positioned(
                bottom: 12,
                right: 12,
                child: _buildFollowToggle(),
              ),
            ],
          );
        },
        loading: () => _buildLoadingState(),
        error: (err, _) => _buildErrorState(err.toString()),
      ),
    );
  }

  void _updateLocation(PatientLiveLocation location) async {
    final newPos = LatLng(location.latitude, location.longitude);

    if (mounted) {
      setState(() {
        _currentPosition = newPos;
        _markers = _createMarkers(newPos);
      });
    }

    if (_followMode || _isFirstLocation) {
      _isFirstLocation = false;
      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLng(newPos));
    }
  }

  Set<Marker> _createMarkers(LatLng pos) {
    return {
      Marker(
        markerId: const MarkerId('patient_marker'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(title: 'Patient Current Location'),
      ),
    };
  }

  Widget _buildLocationBadge(PatientLiveLocation? location) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Live Tracking',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowToggle() {
    return FloatingActionButton.small(
      heroTag: 'follow_toggle',
      onPressed: () => setState(() => _followMode = !_followMode),
      backgroundColor: _followMode ? Colors.teal : Colors.white,
      foregroundColor: _followMode ? Colors.white : Colors.teal,
      child: Icon(_followMode ? Icons.my_location : Icons.location_searching),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Waiting for patient location...',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[100]!,
      highlightColor: Colors.white,
      child: Container(color: Colors.white),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 30),
            const SizedBox(height: 8),
            Text(
              'Connection issue: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
