import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memocare/features/caregiver/presentation/screens/dashboard/viewmodels/caregiver_dashboard_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
//  Design tokens
// ─────────────────────────────────────────────────────────────
class _C {
  static const teal700 = Color(0xFF00695C);
  static const teal500 = Color(0xFF00897B);
  static const teal50 = Color(0xFFE0F2F1);
  static const teal100 = Color(0xFFB2DFDB);
  static const coral = Color(0xFFEF4444);
  static const amber = Color(0xFFF59E0B);
  static const green = Color(0xFF16A34A);
  static const card = Color(0xFFFFFFFF);
  static const ink900 = Color(0xFF0D1B1E);
  static const ink600 = Color(0xFF455A64);
  static const ink400 = Color(0xFF8A9EA2);
  static const ink100 = Color(0xFFECF0F1);
}

// ─────────────────────────────────────────────────────────────
//  Domain model
// ─────────────────────────────────────────────────────────────
enum _Safety { safe, warning, breach, unknown }

class _LiveStatus {
  final _Safety safety;
  final String? locationName;
  final double? distanceMetres;
  final double? homeRadiusMetres;
  final int? battery;
  final DateTime? lastActive;
  final String? patientPhone;

  // reminder counts carried over from dashState
  final int completedReminders;
  final int totalReminders;

  const _LiveStatus({
    required this.safety,
    this.locationName,
    this.distanceMetres,
    this.homeRadiusMetres,
    this.battery,
    this.lastActive,
    this.patientPhone,
    this.completedReminders = 0,
    this.totalReminders = 0,
  });

  bool get isSafe => safety == _Safety.safe;

  String get distanceLabel {
    if (distanceMetres == null) return '—';
    return distanceMetres! < 1000
        ? '${distanceMetres!.round()} m from home'
        : '${(distanceMetres! / 1000).toStringAsFixed(1)} km from home';
  }

  String get lastActiveLabel {
    if (lastActive == null) return 'Unknown';
    final diff = DateTime.now().difference(lastActive!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('h:mm a').format(lastActive!);
  }
}

// ─────────────────────────────────────────────────────────────
//  Provider — streams patient_locations + patient_home_locations
// ─────────────────────────────────────────────────────────────

// Args bundle so family key is a single object
class _PatientStatusArgs {
  final String patientId;
  final int completedReminders;
  final int totalReminders;
  const _PatientStatusArgs(
      this.patientId, this.completedReminders, this.totalReminders);

  @override
  bool operator ==(Object o) =>
      o is _PatientStatusArgs &&
      o.patientId == patientId &&
      o.completedReminders == completedReminders &&
      o.totalReminders == totalReminders;

  @override
  int get hashCode =>
      Object.hash(patientId, completedReminders, totalReminders);
}

final _liveStatusProvider =
    StreamProvider.family<_LiveStatus, _PatientStatusArgs>(
  (ref, args) async* {
    final client = Supabase.instance.client;

    // ── fetch helper ──────────────────────────────────────────
    Future<_LiveStatus> fetch() async {
      final results = await Future.wait([
        // Current location
        client
            .from('patient_locations')
            .select('lat,lng,updated_at')
            .eq('patient_id', args.patientId)
            .maybeSingle(),
        // Home location + radius
        client
            .from('patient_home_locations')
            .select('latitude,longitude,radius')
            .eq('patient_id', args.patientId)
            .maybeSingle(),
        // Phone number
        // client
        //     .from('patients')
        //     .select('phone')
        //     .eq('id', args.patientId)
        //     .maybeSingle(),
      ]);

      final loc = results[0] as Map<String, dynamic>?;
      final home = results[1] as Map<String, dynamic>?;
      final prof = results[2] as Map<String, dynamic>?;

      if (loc == null) {
        return _LiveStatus(
          safety: _Safety.unknown,
          completedReminders: args.completedReminders,
          totalReminders: args.totalReminders,
        );
      }

      final lat = (loc['latitude'] as num?)?.toDouble();
      final lng = (loc['longitude'] as num?)?.toDouble();
      final battery = loc['battery_level'] as int?;
      final lastSeen = loc['updated_at'] != null
          ? DateTime.tryParse(loc['updated_at'] as String)
          : null;
      final locName = loc['location_name'] as String?;

      double? dist;
      double? radius;
      _Safety safety = _Safety.unknown;

      if (home != null && lat != null && lng != null) {
        final hLat = (home['latitude'] as num).toDouble();
        final hLng = (home['longitude'] as num).toDouble();
        radius = (home['radius'] as num?)?.toDouble() ?? 200;
        dist = _haversine(lat, lng, hLat, hLng);

        if (dist <= radius) {
          safety = _Safety.safe;
        } else if (dist <= radius * 1.5) {
          safety = _Safety.warning;
        } else {
          safety = _Safety.breach;
        }
      }

      // Low battery upgrades safe → warning
      if (battery != null && battery <= 15 && safety == _Safety.safe) {
        safety = _Safety.warning;
      }

      return _LiveStatus(
        safety: safety,
        locationName: locName,
        distanceMetres: dist,
        homeRadiusMetres: radius,
        battery: battery,
        lastActive: lastSeen,
        patientPhone: prof?['phone'] as String?,
        completedReminders: args.completedReminders,
        totalReminders: args.totalReminders,
      );
    }

    // Initial value
    yield await fetch();

    // Real-time subscription on patient_locations
    final ctrl = StreamController<_LiveStatus>();

    final channel = client
        .channel('psc_${args.patientId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'patient_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: args.patientId,
          ),
          callback: (_) async => ctrl.add(await fetch()),
        )
        .subscribe();

    ref.onDispose(() {
      ctrl.close();
      client.removeChannel(channel);
    });

    yield* ctrl.stream;
  },
);

// ─────────────────────────────────────────────────────────────
//  Haversine
// ─────────────────────────────────────────────────────────────
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

double _rad(double d) => d * math.pi / 180;

// ─────────────────────────────────────────────────────────────
//  Public widget  (replaces the old PatientStatusCard)
// ─────────────────────────────────────────────────────────────
class PatientStatusCard extends ConsumerWidget {
  /// [patientId] is required for the live query.
  /// Reminder counts are passed from the dashboard viewmodel so
  /// we avoid a second Supabase query for data already in memory.
  const PatientStatusCard({
    super.key,
    required this.patientId,
    this.completedReminders = 0,
    this.totalReminders = 0,
    // Legacy parameter kept for backwards compat — ignored.
    // ignore: avoid_unused_constructor_parameters
    PatientStatus? status,
  });

  final String patientId;
  final int completedReminders;
  final int totalReminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args =
        _PatientStatusArgs(patientId, completedReminders, totalReminders);
    final async = ref.watch(_liveStatusProvider(args));

    return async.when(
      data: (s) => _Card(status: s),
      loading: () => _Skeleton(),
      error: (e, _) => _ErrorBanner(error: e.toString()),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Loaded card
// ─────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  const _Card({required this.status});
  final _LiveStatus status;

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg(status.safety);
    final theme = Theme.of(context);

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
          // ── Header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PulseIcon(safety: status.safety, color: cfg.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cfg.headline,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cfg.color,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (status.locationName != null)
                        _InfoRow(
                          icon: Icons.place_rounded,
                          text: status.locationName!,
                          color: _C.ink600,
                        ),
                      _InfoRow(
                        icon: Icons.home_rounded,
                        text: status.distanceLabel,
                        color: cfg.color,
                      ),
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        text: 'Active ${status.lastActiveLabel}',
                        color: _C.ink400,
                      ),
                    ],
                  ),
                ),
                // Call button
                if (status.patientPhone != null)
                  _CallButton(phone: status.patientPhone!),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────
          const Divider(height: 1, color: _C.ink100),

          // ── Stats + battery row ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Row(
              children: [
                _StatCell(
                  value: '${status.completedReminders}',
                  label: 'Done',
                  color: _C.teal500,
                ),
                _VDiv(),
                _StatCell(
                  value: '${status.totalReminders - status.completedReminders}',
                  label: 'Pending',
                  color: _C.amber,
                ),
                _VDiv(),
                _StatCell(
                  value: '${status.totalReminders}',
                  label: 'Total',
                  color: _C.ink600,
                ),
                _VDiv(),
                _BatteryCell(level: status.battery),
              ],
            ),
          ),

          // ── Distance progress bar (only when zone known) ─────
          if (status.distanceMetres != null && status.homeRadiusMetres != null)
            _DistanceBar(
              distance: status.distanceMetres!,
              radius: status.homeRadiusMetres!,
              color: cfg.color,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Distance progress bar
// ─────────────────────────────────────────────────────────────
class _DistanceBar extends StatelessWidget {
  const _DistanceBar({
    required this.distance,
    required this.radius,
    required this.color,
  });

  final double distance;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // fill = distance / (radius * 2), capped at 1
    final fill = (distance / (radius * 2)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distance from home',
                style: const TextStyle(fontSize: 11, color: _C.ink400),
              ),
              Text(
                '${distance.round()} m / ${radius.round()} m safe zone',
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 6,
              backgroundColor: _C.ink100,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Pulsing status icon
// ─────────────────────────────────────────────────────────────
class _PulseIcon extends StatefulWidget {
  const _PulseIcon({required this.safety, required this.color});
  final _Safety safety;
  final Color color;

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _ring = Tween(begin: 0.8, end: 1.35)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (_shouldPulse) _ctrl.repeat();
  }

  bool get _shouldPulse =>
      widget.safety == _Safety.breach || widget.safety == _Safety.warning;

  @override
  void didUpdateWidget(covariant _PulseIcon old) {
    super.didUpdateWidget(old);
    if (_shouldPulse && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!_shouldPulse) {
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
    final c = _cfg(widget.safety);
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(alignment: Alignment.center, children: [
        if (_shouldPulse)
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
                    color: widget.color.withOpacity(0.3 * (1 - _ctrl.value)),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(c.icon, color: widget.color, size: 20),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Call button
// ─────────────────────────────────────────────────────────────
class _CallButton extends StatelessWidget {
  const _CallButton({required this.phone});
  final String phone;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.green.withOpacity(0.3)),
        ),
        child: const Icon(Icons.phone_rounded, color: _C.green, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Small reusable bits
// ─────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: color, height: 1.3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(
      {required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: _C.ink400)),
        ]),
      );
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
      child: Column(children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 2),
        Text(
          level != null ? '$level%' : '—',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 2),
        const Text('Battery', style: TextStyle(fontSize: 11, color: _C.ink400)),
      ]),
    );
  }
}

class _VDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1,
      height: 44,
      color: _C.ink100,
      margin: const EdgeInsets.symmetric(horizontal: 2));
}

// ─────────────────────────────────────────────────────────────
//  Config helper
// ─────────────────────────────────────────────────────────────
class _Cfg {
  final Color color;
  final IconData icon;
  final String headline;
  const _Cfg({required this.color, required this.icon, required this.headline});
}

_Cfg _cfg(_Safety s) {
  switch (s) {
    case _Safety.safe:
      return const _Cfg(
        color: _C.green,
        icon: Icons.shield_rounded,
        headline: 'Patient is Safe',
      );
    case _Safety.warning:
      return const _Cfg(
        color: _C.amber,
        icon: Icons.warning_amber_rounded,
        headline: 'Approaching Boundary',
      );
    case _Safety.breach:
      return const _Cfg(
        color: _C.coral,
        icon: Icons.crisis_alert_rounded,
        headline: 'Outside Safe Zone!',
      );
    case _Safety.unknown:
      return const _Cfg(
        color: _C.ink400,
        icon: Icons.help_outline_rounded,
        headline: 'Location Unknown',
      );
  }
}

// ─────────────────────────────────────────────────────────────
//  Skeleton & error
// ─────────────────────────────────────────────────────────────
class _Skeleton extends StatefulWidget {
  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
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
          height: 160,
          decoration: BoxDecoration(
            color: _C.ink100.withOpacity(op),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) => Container(
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
            child: Text('Failed to load patient status',
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w500)),
          ),
        ]),
      );
}
