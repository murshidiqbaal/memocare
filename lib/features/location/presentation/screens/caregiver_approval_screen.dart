import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/flutter_map.dart' show CircleMarker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dementia_care_app/features/auth/providers/auth_provider.dart';
import 'package:dementia_care_app/features/location/models/location_change_request.dart';
import 'package:dementia_care_app/features/location/providers/safezone_providers.dart';

/// Caregiver screen listing pending home location change requests.
/// Caregivers can approve or reject each request from linked patients.
class CaregiverApprovalScreen extends ConsumerWidget {
  const CaregiverApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caregiverId = ref.watch(userProfileProvider).value?.id ?? '';
    final requestsAsync =
        ref.watch(pendingLocationRequestsProvider(caregiverId));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Location Requests',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.invalidate(pendingLocationRequestsProvider(caregiverId)),
          )
        ],
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading requests: $e',
              style: GoogleFonts.outfit(color: Colors.red)),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return _buildEmpty();
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(pendingLocationRequestsProvider(caregiverId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _RequestCard(
                request: requests[i],
                caregiverId: caregiverId,
                onDecision: () => ref
                    .invalidate(pendingLocationRequestsProvider(caregiverId)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 64, color: Colors.green.shade300),
          const SizedBox(height: 16),
          Text('No pending requests',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('All location change requests have been reviewed.',
              style: GoogleFonts.outfit(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final LocationChangeRequest request;
  final String caregiverId;
  final VoidCallback onDecision;

  const _RequestCard({
    required this.request,
    required this.caregiverId,
    required this.onDecision,
  });

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _loading = false;

  Future<void> _decide({required bool approve}) async {
    setState(() => _loading = true);
    try {
      final svc = ref.read(locationChangeRequestServiceProvider);
      if (approve) {
        await svc.approveRequest(
          requestId: widget.request.id,
          caregiverId: widget.caregiverId,
          request: widget.request,
          label: 'Home',
        );
      } else {
        await svc.rejectRequest(
          requestId: widget.request.id,
          caregiverId: widget.caregiverId,
        );
      }
      widget.onDecision();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMap() async {
    final lat = widget.request.requestedLatitude;
    final lng = widget.request.requestedLongitude;
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini map preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 160,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter:
                      LatLng(req.requestedLatitude, req.requestedLongitude),
                  initialZoom: 15,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.memocare.app',
                  ),
                  CircleLayer(circles: [
                    CircleMarker(
                      point:
                          LatLng(req.requestedLatitude, req.requestedLongitude),
                      radius: req.requestedRadiusMeters.toDouble(),
                      useRadiusInMeter: true,
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ]),
                  MarkerLayer(markers: [
                    Marker(
                      point:
                          LatLng(req.requestedLatitude, req.requestedLongitude),
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.home_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${req.requestedLatitude.toStringAsFixed(5)}, ${req.requestedLongitude.toStringAsFixed(5)}',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ),
                    TextButton(
                      onPressed: _openMap,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text('Open Maps',
                          style: GoogleFonts.outfit(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.radar_rounded,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Radius: ${req.requestedRadiusMeters} m',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: Colors.grey.shade700)),
                    const Spacer(),
                    Text(
                      _formatDate(req.createdAt),
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _decide(approve: false),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.red, size: 18),
                          label: Text('Reject',
                              style: GoogleFonts.outfit(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _decide(approve: true),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text('Approve', style: GoogleFonts.outfit()),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
