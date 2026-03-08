import 'package:dementia_care_app/data/models/patient_live_location.dart';
import 'package:dementia_care_app/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';

// import '../../../../data/models/patient_live_location.dart';
// import '../../../../providers/location_providers.dart';

/// LivePatientMap — performance-optimised realtime tracking for the
/// Caregiver Dashboard, now powered by flutter_map + OSM tiles.
///
/// Architecture notes:
///  • [listenManual] is used (not ref.watch) to avoid rebuilding the entire
///    map widget tree on every location tick — only markers update.
///  • [_followMode] auto-pans the camera; toggled off when user manually pans.
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
  final MapController _mapController = MapController();

  ProviderSubscription<AsyncValue<PatientLiveLocation?>>? _locationSub;

  LatLng? _currentPosition;
  bool _isFirstLocation = true;
  bool _followMode = true;

  @override
  void initState() {
    super.initState();
    // Listen outside build to avoid full widget rebuild on each tick
    _locationSub = ref.listenManual<AsyncValue<PatientLiveLocation?>>(
      patientLiveLocationProvider(widget.patientId),
      (previous, next) {
        next.whenData((location) {
          if (location != null) _updateLocation(location);
        });
      },
    );
  }

  @override
  void dispose() {
    _locationSub?.close();
    super.dispose();
  }

  void _updateLocation(PatientLiveLocation location) {
    final newPos = LatLng(location.latitude, location.longitude);
    if (!mounted) return;

    setState(() => _currentPosition = newPos);

    if (_followMode || _isFirstLocation) {
      _isFirstLocation = false;
      _mapController.move(newPos, _mapController.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.patientId.isEmpty) {
      return SizedBox(height: widget.height);
    }

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

          final pos = _currentPosition ??
              LatLng(location!.latitude, location.longitude);

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: pos,
                  initialZoom: 15,
                  // Detect manual pan → disable follow mode
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture && _followMode && mounted) {
                      setState(() => _followMode = false);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.memocare.app',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pos,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.teal.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Live badge
              Positioned(
                top: 12,
                left: 12,
                child: _buildLocationBadge(),
              ),

              // Follow toggle
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

  Widget _buildLocationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration:
                  BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
          ),
          SizedBox(width: 6),
          Text(
            'Live Tracking',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowToggle() {
    return FloatingActionButton.small(
      heroTag: 'follow_toggle_${widget.patientId}',
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
              fontWeight: FontWeight.w500,
            ),
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
