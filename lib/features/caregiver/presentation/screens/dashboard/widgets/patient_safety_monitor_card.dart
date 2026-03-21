import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
//  Design tokens (kept in sync with caregiver_dashboard_tab.dart)
// ─────────────────────────────────────────────────────────────
class _C {
  static const teal900 = Color(0xFF003D36);
  static const teal700 = Color(0xFF00695C);
  static const teal500 = Color(0xFF00897B);
  static const teal100 = Color(0xFFB2DFDB);
  static const teal50 = Color(0xFFE0F2F1);
  static const coral = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
  static const green = Color(0xFF22C55E);
  static const greenSoft = Color(0xFFDCFCE7);
  static const redSoft = Color(0xFFFEF2F2);
  static const card = Color(0xFFFFFFFF);
  static const ink900 = Color(0xFF0D1B1E);
  static const ink600 = Color(0xFF455A64);
  static const ink400 = Color(0xFF8A9EA2);
  static const ink100 = Color(0xFFECF0F1);
}

// ─────────────────────────────────────────────────────────────
//  Safety data model
// ─────────────────────────────────────────────────────────────
enum SafetyStatus { safe, warning, breach, unknown }

class PatientSafetyData {
  final SafetyStatus status;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final double? distanceFromHome; // metres
  final double? safeZoneRadius; // metres
  final int? batteryLevel; // 0-100
  final DateTime? lastSeen;
  final bool isLocationSharing;

  const PatientSafetyData({
    this.status = SafetyStatus.unknown,
    this.latitude,
    this.longitude,
    this.locationName,
    this.distanceFromHome,
    this.safeZoneRadius,
    this.batteryLevel,
    this.lastSeen,
    this.isLocationSharing = false,
  });

  bool get isInSafeZone {
    if (distanceFromHome == null || safeZoneRadius == null) return false;
    return distanceFromHome! <= safeZoneRadius!;
  }

  String get distanceLabel {
    if (distanceFromHome == null) return '—';
    final d = distanceFromHome!;
    return d < 1000
        ? '${d.round()} m from home'
        : '${(d / 1000).toStringAsFixed(1)} km from home';
  }

  String get lastSeenLabel {
    if (lastSeen == null) return 'Unknown';
    final diff = DateTime.now().difference(lastSeen!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─────────────────────────────────────────────────────────────
//  Provider  — streams patient_locations + safe_zones
// ─────────────────────────────────────────────────────────────
final patientSafetyProvider = StreamProvider.family<PatientSafetyData, String>(
  (ref, patientId) async* {
    final client = Supabase.instance.client;

    Future<PatientSafetyData> _fetch() async {
      // Parallel fetch
      final results = await Future.wait([
        client
            .from('patient_locations')
            .select('lat,lng,updated_at')
            .eq('patient_id', patientId)
            .maybeSingle(),
        client
            .from('safe_zones')
            .select('latitude,longitude,radius')
            .eq('patient_id', patientId)
            .eq('is_active', true)
            .maybeSingle(),
      ]);

      final loc = results[0] as Map<String, dynamic>?;
      final zone = results[1] as Map<String, dynamic>?;

      if (loc == null) {
        return const PatientSafetyData(status: SafetyStatus.unknown);
      }

      final lat = (loc['lat'] as num?)?.toDouble();
      final lng = (loc['lng'] as num?)?.toDouble();
      // final battery = loc['battery_level'] as int?;
      final lastSeen = loc['updated_at'] != null
          ? DateTime.tryParse(loc['updated_at'] as String)
          : null;
      // final isSharing = loc['is_sharing'] as bool? ?? false;
      // final locName = loc['location_name'] as String?;

      double? distance;
      double? radius;
      SafetyStatus status = SafetyStatus.unknown;

      if (zone != null && lat != null && lng != null) {
        final homeLat = (zone['latitude'] as num).toDouble();
        final homeLng = (zone['longitude'] as num).toDouble();
        radius = (zone['radius'] as num).toDouble();
        distance = _haversine(lat, lng, homeLat, homeLng);

        if (distance <= radius) {
          status = SafetyStatus.safe;
        } else if (distance <= radius * 1.5) {
          status = SafetyStatus.warning;
        } else {
          status = SafetyStatus.breach;
        }
      } else {
        status = SafetyStatus.safe; // no zone set = no breach
      }

      // Battery warning overrides to warning if low
      // if (battery != null && battery <= 15 && status == SafetyStatus.safe) {
      //   status = SafetyStatus.warning;
      // }

      return PatientSafetyData(
        status: status,
        latitude: lat,
        longitude: lng,
        // locationName: locName,
        distanceFromHome: distance,
        safeZoneRadius: radius,
        // batteryLevel: battery,
        lastSeen: lastSeen,
        // isLocationSharing: isSharing,
      );
    }

    // Initial value
    yield await _fetch();

    // Real-time updates via Supabase realtime
    final ctrl = StreamController<PatientSafetyData>();

    final channel = client
        .channel('safety_$patientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'patient_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: patientId,
          ),
          callback: (_) async {
            ctrl.add(await _fetch());
          },
        )
        .subscribe();

    ref.onDispose(() {
      ctrl.close();
      client.removeChannel(channel);
    });

    yield* ctrl.stream;
  },
);

// Haversine distance in metres
double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _rad(double deg) => deg * math.pi / 180;

// ─────────────────────────────────────────────────────────────
//  Public widget
// ─────────────────────────────────────────────────────────────
class PatientSafetyMonitorCard extends ConsumerWidget {
  const PatientSafetyMonitorCard({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.caregiverId,
  });

  final String patientId;
  final String patientName;
  final String caregiverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safetyAsync = ref.watch(patientSafetyProvider(patientId));

    return safetyAsync.when(
      data: (data) => _SafetyCard(data: data, patientName: patientName),
      loading: () => _SafetyCardSkeleton(),
      error: (e, _) => _SafetyCardError(error: e.toString()),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Loaded card
// ─────────────────────────────────────────────────────────────
class _SafetyCard extends StatelessWidget {
  const _SafetyCard({required this.data, required this.patientName});

  final PatientSafetyData data;
  final String patientName;

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig(data.status);

    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cfg.color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 0,
            offset: Offset(-1, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Animated status icon
                _StatusIcon(status: data.status, color: cfg.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cfg.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cfg.color,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cfg.subtitle(patientName),
                        style: const TextStyle(
                          fontSize: 12,
                          color: _C.ink600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Last seen pill
                _LastSeenPill(label: data.lastSeenLabel),
              ],
            ),
          ),

          // ── Divider ──
          Divider(height: 1, color: _C.ink100),

          // ── Stats grid ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Row(
              children: [
                _StatCell(
                  icon: Icons.home_rounded,
                  label: 'Distance',
                  value: data.distanceLabel,
                  color: cfg.color,
                ),
                _VerticalDivider(),
                _StatCell(
                  icon: Icons.radar_rounded,
                  label: 'Safe zone',
                  value: data.safeZoneRadius != null
                      ? '${data.safeZoneRadius!.round()} m radius'
                      : 'Not set',
                  color: _C.teal500,
                ),
                _VerticalDivider(),
                _BatteryCell(level: data.batteryLevel),
              ],
            ),
          ),

          // ── Location name strip (if available) ──
          if (data.locationName != null && data.locationName!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: cfg.color.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(19),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.place_rounded, size: 14, color: cfg.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      data.locationName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: cfg.color,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!data.isLocationSharing)
                    Row(children: [
                      Icon(Icons.location_off_rounded,
                          size: 12, color: _C.ink400),
                      const SizedBox(width: 4),
                      const Text(
                        'Location sharing off',
                        style: TextStyle(fontSize: 11, color: _C.ink400),
                      ),
                    ]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Animated status icon
// ─────────────────────────────────────────────────────────────
class _StatusIcon extends StatefulWidget {
  const _StatusIcon({required this.status, required this.color});
  final SafetyStatus status;
  final Color color;

  @override
  State<_StatusIcon> createState() => _StatusIconState();
}

class _StatusIconState extends State<_StatusIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _ring = Tween(begin: 0.85, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    // Only pulse on breach or warning
    if (widget.status == SafetyStatus.breach ||
        widget.status == SafetyStatus.warning) {
      _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _StatusIcon old) {
    super.didUpdateWidget(old);
    if (widget.status == SafetyStatus.breach ||
        widget.status == SafetyStatus.warning) {
      if (!_ctrl.isAnimating) _ctrl.repeat();
    } else {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig(widget.status);
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(alignment: Alignment.center, children: [
        // Pulse ring (breach/warning only)
        if (widget.status != SafetyStatus.safe &&
            widget.status != SafetyStatus.unknown)
          AnimatedBuilder(
            animation: _ring,
            builder: (_, __) => Transform.scale(
              scale: _ring.value,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withOpacity(0.35 * (1 - _ctrl.value)),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        // Core circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(cfg.icon, color: widget.color, size: 20),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Stat cells
// ─────────────────────────────────────────────────────────────
class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _C.ink900,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _C.ink400),
          ),
        ],
      ),
    );
  }
}

class _BatteryCell extends StatelessWidget {
  const _BatteryCell({required this.level});
  final int? level;

  @override
  Widget build(BuildContext context) {
    final color = level == null
        ? _C.ink400
        : level! <= 15
            ? _C.coral
            : level! <= 30
                ? _C.amber
                : _C.green;

    final icon = level == null
        ? Icons.battery_unknown_rounded
        : level! <= 15
            ? Icons.battery_alert_rounded
            : level! <= 50
                ? Icons.battery_4_bar_rounded
                : Icons.battery_full_rounded;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            level != null ? '$level%' : '—',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Battery',
            style: TextStyle(fontSize: 10, color: _C.ink400),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      color: _C.ink100,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _LastSeenPill extends StatelessWidget {
  const _LastSeenPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _C.teal50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.schedule_rounded, size: 11, color: _C.teal700),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: _C.teal700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Status config helper
// ─────────────────────────────────────────────────────────────
class _StatusCfg {
  final Color color;
  final IconData icon;
  final String label;
  final String Function(String name) subtitle;

  const _StatusCfg({
    required this.color,
    required this.icon,
    required this.label,
    required this.subtitle,
  });
}

_StatusCfg _statusConfig(SafetyStatus s) {
  switch (s) {
    case SafetyStatus.safe:
      return _StatusCfg(
        color: const Color(0xFF16A34A),
        icon: Icons.shield_rounded,
        label: 'Safe & Accounted For',
        subtitle: (name) => '$name is within the safe zone.',
      );
    case SafetyStatus.warning:
      return _StatusCfg(
        color: _C.amber,
        icon: Icons.warning_amber_rounded,
        label: 'Approaching Boundary',
        subtitle: (name) => '$name is near the edge of the safe zone.',
      );
    case SafetyStatus.breach:
      return _StatusCfg(
        color: _C.coral,
        icon: Icons.crisis_alert_rounded,
        label: 'Outside Safe Zone',
        subtitle: (name) => '$name has left the designated safe area!',
      );
    case SafetyStatus.unknown:
      return _StatusCfg(
        color: _C.ink400,
        icon: Icons.help_outline_rounded,
        label: 'Location Unknown',
        subtitle: (name) => 'Unable to determine $name\'s location.',
      );
  }
}

// ─────────────────────────────────────────────────────────────
//  Skeleton loader
// ─────────────────────────────────────────────────────────────
class _SafetyCardSkeleton extends StatefulWidget {
  @override
  State<_SafetyCardSkeleton> createState() => _SafetyCardSkeletonState();
}

class _SafetyCardSkeletonState extends State<_SafetyCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final op = 0.35 + _ctrl.value * 0.35;
        return Container(
          height: 136,
          decoration: BoxDecoration(
            color: _C.ink100.withOpacity(op),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Error state
// ─────────────────────────────────────────────────────────────
class _SafetyCardError extends StatelessWidget {
  const _SafetyCardError({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.coral.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, color: _C.coral, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Failed to load safety status',
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }
}
