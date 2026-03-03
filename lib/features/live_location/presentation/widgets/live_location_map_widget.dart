import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';

import '../../../patient_selection/providers/patient_selection_provider.dart';
import '../../data/patient_location_model.dart';
import '../../providers/live_location_provider.dart';

class LiveLocationMapWidget extends ConsumerStatefulWidget {
  final double height;

  const LiveLocationMapWidget({super.key, this.height = 300});

  @override
  ConsumerState<LiveLocationMapWidget> createState() =>
      _LiveLocationMapWidgetState();
}

class _LiveLocationMapWidgetState extends ConsumerState<LiveLocationMapWidget>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  bool _followPatient = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientSelectionProvider);

    if (!patientState.isPatientSelected) {
      return _buildShell(child: _buildNoPatientState());
    }

    final locationAsync = ref.watch(liveLocationStreamProvider);

    return _buildShell(
      child: Stack(
        children: [
          locationAsync.when(
            loading: () => _buildShimmer(),
            error: (err, _) => _buildErrorState(err.toString()),
            data: (location) {
              if (location == null) return _buildWaitingState();
              return _buildMap(location);
            },
          ),

          // Overlay controls
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                locationAsync.whenOrNull(
                      data: (loc) =>
                          loc != null ? _buildLastUpdatedBadge(loc) : null,
                    ) ??
                    const SizedBox.shrink(),
                _buildFollowToggle(),
              ],
            ),
          ),

          // Stale banner
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

  Widget _buildMap(PatientLocation location) {
    final latLng = LatLng(location.latitude, location.longitude);

    if (_followPatient) {
      try {
        _mapController.move(latLng, 16.5);
      } catch (_) {}
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: latLng,
        initialZoom: 16.5,
        onPositionChanged: (position, hasGesture) {
          if (hasGesture && _followPatient && mounted) {
            setState(() => _followPatient = false);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.memocare.app',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: latLng,
              width: 44,
              height: 44,
              child: Tooltip(
                message:
                    '📍 Patient Location\n${_formatTimeAgo(location.updatedAt)}',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.teal.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

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
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecent
                    ? Color.lerp(Colors.green.shade300, Colors.green.shade700,
                        _pulseAnimation.value)
                    : Colors.orange,
              ),
            ),
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

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
