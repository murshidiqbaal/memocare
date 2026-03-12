// lib/screens/caregiver/dashboard/widgets/sos_alert_banner.dart
//
// Realtime SOS alert banner for the caregiver dashboard.
//
// Watches `caregiverSosStreamProvider` and shows a dismissable red banner
// for every active alert. Each banner has:
//   • Pulsing indicator
//   • Patient ID (or "Unknown patient" if name unavailable)
//   • Time elapsed
//   • GPS coordinates (if available)
//   • "Acknowledge" and "View Details" action buttons
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:memocare/data/models/sos_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:memocare/providers/sos_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top-level widget — mounted once in CaregiverDashboardTab
// ─────────────────────────────────────────────────────────────────────────────

class CaregiverSosAlertBanner extends ConsumerWidget {
  const CaregiverSosAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(caregiverSosStreamProvider);

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();
        return Column(
          children:
              alerts.map((alert) => _SosBannerCard(alert: alert)).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual alert card
// ─────────────────────────────────────────────────────────────────────────────

class _SosBannerCard extends ConsumerStatefulWidget {
  final SosAlert alert;
  const _SosBannerCard({required this.alert});

  @override
  ConsumerState<_SosBannerCard> createState() => _SosBannerCardState();
}

class _SosBannerCardState extends ConsumerState<_SosBannerCard>
    with SingleTickerProviderStateMixin {
  // ── Pulsing animation ─────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // ── Elapsed-time ticker ───────────────────────────────────────────────────
  Timer? _ticker;

  bool _isAcknowledging = false;
  bool _dismissed = false; // local optimistic hide

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Refresh elapsed time every 30 s
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _acknowledge() async {
    if (_isAcknowledging) return;
    setState(() => _isAcknowledging = true);

    try {
      final acknowledge = ref.read(sosAcknowledgeProvider);
      await acknowledge(widget.alert.id);
      if (mounted) setState(() => _dismissed = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to acknowledge: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isAcknowledging = false);
      }
    }
  }

  Future<void> _openMap() async {
    final lat = widget.alert.latitude;
    final lng = widget.alert.longitude;
    if (lat == null || lng == null) return;
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final alert = widget.alert;
    final elapsed = DateTime.now().difference(alert.createdAt);
    final elapsedStr =
        elapsed.inMinutes < 1 ? 'Just now' : '${elapsed.inMinutes} min ago';

    return _AnimatedCard(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  // Pulsing dot
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Opacity(
                      opacity: _pulseAnim.value,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 26),
                  const SizedBox(width: 8),
                  const Text(
                    'SOS EMERGENCY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    elapsedStr,
                    style: TextStyle(color: Colors.red.shade100, fontSize: 12),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A patient needs immediate help!',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  if (alert.latitude != null && alert.longitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: InkWell(
                        onTap: _openMap,
                        child: Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${alert.latitude!.toStringAsFixed(4)}, '
                              '${alert.longitude!.toStringAsFixed(4)}  (tap to open map)',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Action buttons ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  // Acknowledge
                  Expanded(
                    child: _isAcknowledging
                        ? const Center(
                            child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)))
                        : FilledButton.icon(
                            onPressed: _acknowledge,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Acknowledge',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                  ),
                  const SizedBox(width: 10),
                  // Open map (if location available)
                  if (alert.latitude != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openMap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Map'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slide-in animation wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  const _AnimatedCard({required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _slide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
