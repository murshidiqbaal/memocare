import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../patient_selection/providers/patient_selection_provider.dart';
import '../../data/patient_location_model.dart';
import '../../providers/live_location_provider.dart';

String _formatTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class LiveLocationMapWidget extends ConsumerStatefulWidget {
  final double height;

  const LiveLocationMapWidget({super.key, this.height = 300});

  @override
  ConsumerState<LiveLocationMapWidget> createState() =>
      _LiveLocationMapWidgetState();
}

class _LiveLocationMapWidgetState extends ConsumerState<LiveLocationMapWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _followPatient = true;

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientSelectionProvider);
    final locationAsync = ref.watch(liveLocationStreamProvider);

    if (!patientState.isPatientSelected) {
      return _buildEmptyState(
        icon: Icons.person_search,
        message: 'No Patient Selected',
        subMessage: 'Select a patient to view their live location.',
      );
    }

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          locationAsync.when(
            data: (location) => _buildMap(location),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => _buildEmptyState(
              icon: Icons.error_outline,
              message: 'Failed to load location',
              subMessage: err.toString(),
            ),
          ),

          // Header / Controls Overlay
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLastUpdatedBadge(locationAsync.valueOrNull),
                FloatingActionButton.small(
                  backgroundColor: _followPatient ? Colors.teal : Colors.white,
                  foregroundColor: _followPatient ? Colors.white : Colors.teal,
                  onPressed: () =>
                      setState(() => _followPatient = !_followPatient),
                  child: Icon(_followPatient
                      ? Icons.my_location
                      : Icons.location_searching),
                  tooltip: _followPatient ? 'Stop following' : 'Follow patient',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(PatientLocation? location) {
    if (location == null) {
      return _buildEmptyState(
        icon: Icons.location_off,
        message: 'Waiting for Location',
        subMessage: 'Patient app hasn\'t synced location yet.',
      );
    }

    final latLng = LatLng(location.latitude, location.longitude);

    // Smoothly animate to new location if following
    if (_followPatient) {
      _controller.future.then((mapController) {
        mapController.animateCamera(CameraUpdate.newLatLng(latLng));
      });
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: latLng, zoom: 16),
      onMapCreated: (GoogleMapController controller) {
        if (!_controller.isCompleted) {
          _controller.complete(controller);
        }
      },
      onCameraMoveStarted: () {
        // Stop following when user manually pans map
        if (_followPatient) {
          setState(() {
            _followPatient = false;
          });
        }
      },
      markers: {
        Marker(
          markerId: MarkerId('patient_${location.patientId}'),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              180.0), // Teal approximate hue
          infoWindow: InfoWindow(
            title: 'Patient Location',
            snippet: 'Updated ${_formatTimeAgo(location.updatedAt)}',
          ),
        ),
      },
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildLastUpdatedBadge(PatientLocation? location) {
    if (location == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 14, color: Colors.teal),
          const SizedBox(width: 4),
          Text(
            _formatTimeAgo(location.updatedAt),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required String message,
      required String subMessage}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
