import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../patient_selection/providers/patient_selection_provider.dart';
// From lib/features/live_location/presentation/widgets/
//   → ../../ goes to lib/features/live_location/
//   → ../../../ goes to lib/features/
import '../../data/patient_location_model.dart';
import '../../providers/live_location_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LiveLocationMapWidget
//
// Production-grade Google Maps widget that:
//   ✅ Shows real-time patient location (from liveLocationStreamProvider)
//   ✅ Animates camera smoothly to new positions
//   ✅ Pulsing animated live-dot in the "last updated" badge
//   ✅ Follow / unfollow toggle (stops following on manual pan)
//   ✅ Live "last updated" countdown (ticks every 30s)
//   ✅ Shimmer loading state
//   ✅ "Select a patient" empty state
//   ✅ "Waiting for location" waiting state
//   ✅ Error banner with connectivity icon
//   ✅ Stale location warning banner (> 10 min old)
//   ✅ Complete disposal (map controller, animation, timer)
// ─────────────────────────────────────────────────────────────────────────────
class LiveLocationMapWidget extends ConsumerStatefulWidget {
  final double height;

  const LiveLocationMapWidget({super.key, this.height = 300});

  @override
  ConsumerState<LiveLocationMapWidget> createState() =>
      _LiveLocationMapWidgetState();
}

class _LiveLocationMapWidgetState extends ConsumerState<LiveLocationMapWidget>
    with TickerProviderStateMixin {
  // Google Maps controller (completed once map is created)
  final Completer<GoogleMapController> _mapController = Completer();

  // Follow mode: when true, camera animates to each new position
  bool _followPatient = true;

  // Pulsing animation for live-dot and waiting-state icon
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Clock timer — refreshes the "X ago" label every 30 seconds
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _initPulse();
    _startClockTimer();
  }

  void _initPulse() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {}); // Force "time ago" label refresh
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _clockTimer?.cancel();
    _mapController.future
        .then((c) => c.dispose())
        .catchError((_) {}); // Safe — avoids crash if map never completed
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientSelectionProvider);

    // No patient selected — show friendly empty state
    if (!patientState.isPatientSelected) {
      return _buildShell(child: _buildNoPatientState());
    }

    final locationAsync = ref.watch(liveLocationStreamProvider);

    return _buildShell(
      child: Stack(
        children: [
          // ── Map / Shimmer / Waiting / Error layer ─────────────────────
          locationAsync.when(
            loading: () => _buildShimmer(),
            error: (err, _) => _buildErrorState(err.toString()),
            data: (location) {
              if (location == null) return _buildWaitingState();
              return _buildMap(location);
            },
          ),

          // ── Controls overlay ──────────────────────────────────────────
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Last-updated badge (only when data is available)
                locationAsync.whenOrNull(
                      data: (loc) =>
                          loc != null ? _buildLastUpdatedBadge(loc) : null,
                    ) ??
                    const SizedBox.shrink(),

                // Follow toggle pill
                _buildFollowToggle(),
              ],
            ),
          ),

          // ── Stale location warning banner ─────────────────────────────
          if (locationAsync.valueOrNull?.isStale == true)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildStaleBanner(),
            ),
        ],
      ),
    );
  }

  // ── Map ────────────────────────────────────────────────────────────────────

  Widget _buildMap(PatientLocation location) {
    final latLng = LatLng(location.latitude, location.longitude);

    // Animate camera when in follow mode (non-blocking)
    if (_followPatient) {
      _mapController.future.then((ctrl) {
        ctrl.animateCamera(
          CameraUpdate.newCameraPosition(
              CameraPosition(target: latLng, zoom: 16.5)),
        );
      }).catchError((_) {});
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: latLng, zoom: 16.5),
      onMapCreated: (ctrl) {
        if (!_mapController.isCompleted) {
          _mapController.complete(ctrl);
        }
      },
      // User manually panned → stop auto-follow
      onCameraMoveStarted: () {
        if (_followPatient && mounted) {
          setState(() => _followPatient = false);
        }
      },
      markers: {
        Marker(
          markerId: MarkerId('patient_${location.patientId}'),
          position: latLng,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 1.0),
          infoWindow: InfoWindow(
            title: '📍 Patient Location',
            snippet: _formatTimeAgo(location.updatedAt),
          ),
          zIndex: 2,
        ),
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
      mapToolbarEnabled: false,
      compassEnabled: true,
    );
  }

  // ── Empty / loading states ─────────────────────────────────────────────────

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(color: Colors.grey.shade200),
    );
  }

  Widget _buildNoPatientState() {
    return _buildEmptyState(
      icon: Icons.person_search_outlined,
      color: Colors.blueGrey,
      title: 'No Patient Selected',
      subtitle: 'Use the dropdown above\nor long-press a tab to select.',
    );
  }

  Widget _buildWaitingState() {
    return _buildEmptyState(
      icon: Icons.location_searching,
      color: Colors.amber.shade700,
      title: 'Waiting for Location',
      subtitle: "The patient app hasn't synced\na location yet.",
      isAnimating: true,
    );
  }

  Widget _buildErrorState(String error) {
    return _buildEmptyState(
      icon: Icons.signal_wifi_statusbar_connected_no_internet_4_outlined,
      color: Colors.red.shade400,
      title: 'Location Unavailable',
      subtitle:
          'Could not connect to real-time feed.\nWill retry automatically.',
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    bool isAnimating = false,
  }) {
    return Container(
      color: Colors.grey.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, child) {
                final scale =
                    isAnimating ? 1.0 + (_pulseAnimation.value * 0.15) : 1.0;
                return Transform.scale(scale: scale, child: child!);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 42, color: color),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Badges & controls ──────────────────────────────────────────────────────

  Widget _buildLastUpdatedBadge(PatientLocation location) {
    final timeAgo = _formatTimeAgo(location.updatedAt);
    final isRecent = location.isRecent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.93),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing live dot
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecent
                      ? Color.lerp(Colors.green.shade300, Colors.green.shade700,
                          _pulseAnimation.value)
                      : Colors.orange,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            timeAgo,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowToggle() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => setState(() => _followPatient = !_followPatient),
        child: Tooltip(
          message: _followPatient ? 'Stop following patient' : 'Follow patient',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _followPatient ? Colors.teal : Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _followPatient ? Icons.my_location : Icons.location_searching,
                  color: _followPatient ? Colors.white : Colors.teal,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _followPatient ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _followPatient ? Colors.white : Colors.teal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade700.withOpacity(0.92),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Location may be outdated — patient app has been offline.',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Outer shell (rounded corners + shadow) ─────────────────────────────────

  Widget _buildShell({required Widget child}) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
