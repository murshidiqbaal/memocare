import 'package:dementia_care_app/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/profile_completion_helper.dart';
import '../../../data/models/patient_profile.dart';
import '../../../data/models/safe_zone.dart';
import '../../../features/linking/presentation/controllers/link_controller.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_photo_provider.dart';
import '../../../providers/safe_zone_provider.dart';
import '../../../widgets/editable_avatar.dart';
import 'edit_patient_profile_screen.dart';
import 'safe_zone_picker_screen.dart';
import 'viewmodels/patient_profile_viewmodel.dart';

// ─── THEME ────────────────────────────────────────────────────────────────────
class _T {
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFF8B5CF6);
  static const soft = Color(0xFFEDE9FE);
  static const accent = Color(0xFFC084FC);
  static const bg = Color(0xFFF5F3FF);
  static const gStart = Color(0xFF6D28D9);
  static const gEnd = Color(0xFF9333EA);
  static const dark = Color(0xFF1E1B4B);
  static const mid = Color(0xFF6B7280);
  static const light = Color(0xFF9CA3AF);
}

class PatientProfileScreen extends ConsumerStatefulWidget {
  final String? patientId;
  const PatientProfileScreen({super.key, this.patientId});

  @override
  ConsumerState<PatientProfileScreen> createState() =>
      _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Navigate to edit ──────────────────────────────────────────────────────
  Future<void> _navigateToEdit(PatientProfile? profile) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditPatientProfileScreen(
          existingProfile: profile,
          patientId: widget.patientId,
        ),
      ),
    );
    if (result == true && mounted) {
      ref.invalidate(patientProfileProvider(widget.patientId));
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor: Colors.white,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.logout_rounded,
                color: Colors.red.shade500, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: const Text(
          'Are you sure you want to sign out of Memo Care?',
          style: TextStyle(color: _T.mid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _T.mid)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = patientProfileProvider(widget.patientId);
    final profileState = ref.watch(provider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final isCaregiver = userProfile?.role == 'caregiver';
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      backgroundColor: _T.bg,
      body: profileState.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _T.primary)),
        error: (err, _) => _errorState(err, provider),
        data: (profile) {
          if (profile == null) return _emptyState(scale);

          final pct = ProfileCompletionHelper.calculateCompletion(profile);
          final msg = ProfileCompletionHelper.getCompletionMessage(pct);

          return NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (_, __) => [
              _sliverAppBar(profile, isCaregiver, scale),
            ],
            body: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    16 * scale, 14 * scale, 16 * scale, 120 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Completion
                    if (pct < 100) ...[
                      _completionCard(pct, msg, scale),
                      SizedBox(height: 20 * scale),
                    ],

                    // ── Personal Information ──────────────────────────
                    _section(
                      title: 'Personal Information',
                      icon: Icons.person_rounded,
                      grad: const [Color(0xFF7C3AED), Color(0xFF9333EA)],
                      scale: scale,
                      children: [
                        _tile(
                            'Full Name',
                            profile.fullName ?? 'Not set',
                            Icons.badge_outlined,
                            const Color(0xFF7C3AED),
                            scale),
                        if (profile.dateOfBirth != null)
                          _tile(
                            'Date of Birth',
                            DateFormat('dd MMM yyyy')
                                .format(profile.dateOfBirth!),
                            Icons.cake_outlined,
                            const Color(0xFFEC4899),
                            scale,
                            sub: '${_age(profile.dateOfBirth!)} years old',
                          ),
                        if (profile.gender != null)
                          _tile('Gender', profile.gender!, Icons.wc_rounded,
                              const Color(0xFF8B5CF6), scale),
                        if (profile.phoneNumber != null)
                          _tile(
                              'Phone',
                              profile.phoneNumber!,
                              Icons.phone_outlined,
                              const Color(0xFF10B981),
                              scale),
                        if (profile.address != null)
                          _tile(
                              'Address',
                              profile.address!,
                              Icons.location_on_outlined,
                              const Color(0xFFF59E0B),
                              scale),
                      ],
                    ),
                    SizedBox(height: 20 * scale),

                    // ── Emergency & Medical ───────────────────────────
                    _section(
                      title: 'Emergency & Medical',
                      icon: Icons.local_hospital_rounded,
                      grad: const [Color(0xFFDC2626), Color(0xFFEF4444)],
                      scale: scale,
                      children: [
                        if (profile.emergencyContactName != null)
                          _tile(
                              'Emergency Contact',
                              profile.emergencyContactName!,
                              Icons.contact_emergency_outlined,
                              const Color(0xFFDC2626),
                              scale),
                        if (profile.emergencyContactPhone != null)
                          _tile(
                              'Emergency Phone',
                              profile.emergencyContactPhone!,
                              Icons.phone_in_talk_outlined,
                              const Color(0xFFEA580C),
                              scale),
                        if (profile.medicalNotes != null)
                          _tile(
                              'Medical Notes',
                              profile.medicalNotes!,
                              Icons.medical_services_outlined,
                              const Color(0xFF2563EB),
                              scale),
                        if (!ProfileCompletionHelper.hasCriticalInfo(profile))
                          _warning('Please add emergency contact information',
                              scale),
                      ],
                    ),
                    SizedBox(height: 20 * scale),

                    // ── Hobbies & Interests ───────────────────────────
                    _section(
                      title: 'Hobbies & Interests',
                      icon: Icons.favorite_rounded,
                      grad: const [Color(0xFFEC4899), Color(0xFFF472B6)],
                      badge: 'Optional',
                      scale: scale,
                      children: [
                        _chips(
                          label: 'Activities',
                          chips: profile.hobbies ?? [],
                          color: const Color(0xFFEC4899),
                          icon: Icons.sports_soccer_outlined,
                          hint: 'e.g. Gardening, Reading, Painting',
                          scale: scale,
                        ),
                        _tile(
                            'Favourite Pastime / Craft',
                            profile.favouritePastime ?? 'Not added',
                            Icons.brush_outlined,
                            const Color(0xFFF59E0B),
                            scale),
                        _tile(
                            'Outdoor / Indoor Preference',
                            profile.indoorOutdoorPref ?? 'Not added',
                            Icons.wb_sunny_outlined,
                            const Color(0xFF10B981),
                            scale),
                      ],
                    ),
                    SizedBox(height: 20 * scale),

                    // ── Favourite Things ──────────────────────────────
                    _section(
                      title: 'Favourite Things',
                      icon: Icons.star_rounded,
                      grad: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                      badge: 'Optional',
                      scale: scale,
                      children: [
                        _tile(
                            'Favourite Food / Snack',
                            profile.favouriteFood ?? 'Not added',
                            Icons.restaurant_outlined,
                            const Color(0xFFF59E0B),
                            scale),
                        _tile(
                            'Favourite Drink',
                            profile.favouriteDrink ?? 'Not added',
                            Icons.local_cafe_outlined,
                            const Color(0xFF92400E),
                            scale),
                        _tile(
                            'Favourite Music / Artist',
                            profile.favouriteMusic ?? 'Not added',
                            Icons.music_note_outlined,
                            const Color(0xFF7C3AED),
                            scale),
                        _tile(
                            'Favourite TV Show / Movie',
                            profile.favouriteShow ?? 'Not added',
                            Icons.tv_outlined,
                            const Color(0xFF2563EB),
                            scale),
                        _tile(
                            'Favourite Place / Memory',
                            profile.favouritePlace ?? 'Not added',
                            Icons.place_outlined,
                            const Color(0xFF10B981),
                            scale),
                      ],
                    ),
                    SizedBox(height: 20 * scale),

                    // ── Daily Routine ─────────────────────────────────
                    _section(
                      title: 'Daily Routine',
                      icon: Icons.schedule_rounded,
                      grad: const [Color(0xFF0891B2), Color(0xFF06B6D4)],
                      badge: 'Optional',
                      scale: scale,
                      children: [
                        _tile(
                            'Wake Up Time',
                            profile.wakeUpTime ?? 'Not set',
                            Icons.wb_sunny_outlined,
                            const Color(0xFFF59E0B),
                            scale),
                        _tile(
                            'Bedtime',
                            profile.bedTime ?? 'Not set',
                            Icons.bedtime_outlined,
                            const Color(0xFF6366F1),
                            scale),
                        _tile(
                            'Meal Preferences',
                            profile.mealPreferences ?? 'Not set',
                            Icons.lunch_dining_outlined,
                            const Color(0xFF10B981),
                            scale),
                        _tile(
                            'Exercise / Walk Routine',
                            profile.exerciseRoutine ?? 'Not set',
                            Icons.directions_walk_outlined,
                            const Color(0xFF059669),
                            scale),
                        _tile(
                            'Religious / Cultural Practices',
                            profile.religiousPractices ?? 'Not set',
                            Icons.volunteer_activism_outlined,
                            const Color(0xFF7C3AED),
                            scale),
                        _tile(
                            'Nap / Rest Time',
                            profile.napTime ?? 'Not set',
                            Icons.airline_seat_flat_outlined,
                            const Color(0xFF8B5CF6),
                            scale),
                      ],
                    ),
                    SizedBox(height: 20 * scale),

                    // ── Language & Communication ──────────────────────
                    _section(
                      title: 'Language & Communication',
                      icon: Icons.chat_bubble_outline_rounded,
                      grad: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
                      badge: 'Optional',
                      scale: scale,
                      children: [
                        _tile(
                            'Preferred Language',
                            profile.preferredLanguage ?? 'Not set',
                            Icons.language_outlined,
                            const Color(0xFF0D9488),
                            scale),
                        _tile(
                            'Communication Style',
                            profile.communicationStyle ?? 'Not set',
                            Icons.record_voice_over_outlined,
                            const Color(0xFF0891B2),
                            scale),
                        _tile(
                            'Triggers to Avoid',
                            profile.triggers ?? 'Not set',
                            Icons.warning_amber_outlined,
                            const Color(0xFFDC2626),
                            scale),
                        _tile(
                            'Calming Strategies',
                            profile.calmingStrategies ?? 'Not set',
                            Icons.spa_outlined,
                            const Color(0xFF10B981),
                            scale),
                        _tile(
                            'Important People They Remember',
                            profile.importantPeople ?? 'Not set',
                            Icons.people_outline_rounded,
                            const Color(0xFFEC4899),
                            scale),
                      ],
                    ),
                    SizedBox(height: 20 * scale),

                    // ── Caregiver Access (patients only) ──────────────
                    if (!isCaregiver) ...[
                      _section(
                        title: 'Caregiver Access',
                        icon: Icons.people_alt_rounded,
                        grad: const [Color(0xFF7C3AED), Color(0xFF9333EA)],
                        scale: scale,
                        children: [_linkingContent(scale, profile)],
                      ),
                      SizedBox(height: 20 * scale),

                      _homeLocationSection(scale, profile.id),

                      // Security
                      _section(
                        title: 'Security',
                        icon: Icons.security_rounded,
                        grad: const [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                        scale: scale,
                        children: [
                          _tile(
                              'Biometric Login',
                              'Tap to configure',
                              Icons.fingerprint_rounded,
                              const Color(0xFF1D4ED8),
                              scale),
                        ],
                      ),
                      SizedBox(height: 20 * scale),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── SLIVER APP BAR ────────────────────────────────────────────────────────
  SliverAppBar _sliverAppBar(
      PatientProfile profile, bool isCaregiver, double scale) {
    final isUploading = ref.watch(profilePhotoUploadProvider) is AsyncLoading;

    return SliverAppBar(
      expandedHeight: 268 * scale,
      pinned: true,
      floating: false,
      backgroundColor: _T.gStart,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        widget.patientId != null ? 'Patient Profile' : 'My Profile',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      actions: [
        if (!isCaregiver)
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Profile',
            onPressed: () => _navigateToEdit(
                ref.read(patientProfileProvider(widget.patientId)).value),
          ),
        // ── SIGN OUT ──
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Sign Out',
          onPressed: _signOut,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_T.gStart, _T.gEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(children: [
            // Decorative circles
            Positioned(
              top: -40,
              right: -40,
              child: _blob(180, 0.07),
            ),
            Positioned(
              top: 60,
              right: 80,
              child: _blob(80, 0.04),
            ),
            Positioned(
              bottom: 10,
              left: -30,
              child: _blob(120, 0.05),
            ),

            // Profile content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 30 * scale),

                  // Avatar with glowing ring
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC084FC), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: EditableAvatar(
                      profilePhotoUrl: profile.profileImageUrl,
                      isUploading: isUploading,
                      radius: 52 * scale,
                      onTap: () => ref
                          .read(profilePhotoUploadProvider.notifier)
                          .pickAndUpload(),
                    ),
                  ),
                  SizedBox(height: 14 * scale),

                  Text(
                    profile.fullName ?? 'Memo Care Patient',
                    style: TextStyle(
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4 * scale),

                  if (profile.dateOfBirth != null)
                    Text(
                      '${_age(profile.dateOfBirth!)} years old',
                      style: TextStyle(
                        fontSize: 13 * scale,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  SizedBox(height: 10 * scale),

                  // Badge pill
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14 * scale, vertical: 5 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.28)),
                    ),
                    child: Text(
                      '🧠  Memo Care Patient',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _blob(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  // ── SECTION ───────────────────────────────────────────────────────────────
  Widget _section({
    required String title,
    required IconData icon,
    required List<Color> grad,
    required double scale,
    required List<Widget> children,
    String? badge,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: grad.first.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 16 * scale),
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
                color: _T.dark,
              ),
            ),
          ),
          if (badge != null)
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale, vertical: 3 * scale),
              decoration: BoxDecoration(
                color: _T.soft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10 * scale,
                  color: _T.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ]),
        SizedBox(height: 10 * scale),

        // Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18 * scale),
            boxShadow: [
              BoxShadow(
                color: grad.first.withOpacity(0.08),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18 * scale),
            child: children.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(20 * scale),
                    child: Center(
                      child: Text(
                        'No information added yet',
                        style: TextStyle(
                          color: _T.light,
                          fontSize: 14 * scale,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: _divide(
                      children,
                      Divider(
                        height: 1,
                        color: _T.soft.withOpacity(0.8),
                        indent: 54,
                        endIndent: 16,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── INFO TILE ─────────────────────────────────────────────────────────────
  Widget _tile(
    String label,
    String value,
    IconData icon,
    Color color,
    double scale, {
    String? sub,
  }) {
    final empty =
        value == 'Not set' || value == 'Not added' || value.trim().isEmpty;
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 11 * scale),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36 * scale,
          height: 36 * scale,
          decoration: BoxDecoration(
            color: empty ? const Color(0xFFF3F4F6) : color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: empty ? _T.light : color,
            size: 18 * scale,
          ),
        ),
        SizedBox(width: 14 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10 * scale,
                  color: _T.light,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 3 * scale),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: empty ? _T.light : _T.dark,
                  fontWeight: empty ? FontWeight.w400 : FontWeight.w600,
                  fontStyle: empty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              if (sub != null) ...[
                SizedBox(height: 2 * scale),
                Text(sub,
                    style: TextStyle(fontSize: 11 * scale, color: _T.mid)),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  // ── CHIP ROW ──────────────────────────────────────────────────────────────
  Widget _chips({
    required String label,
    required List<String> chips,
    required Color color,
    required IconData icon,
    required double scale,
    String? hint,
  }) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 11 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36 * scale,
            height: 36 * scale,
            decoration: BoxDecoration(
              color: chips.isEmpty
                  ? const Color(0xFFF3F4F6)
                  : color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: chips.isEmpty ? _T.light : color,
              size: 18 * scale,
            ),
          ),
          SizedBox(width: 14 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10 * scale,
                    color: _T.light,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 6 * scale),
                chips.isEmpty
                    ? Text(
                        hint ?? 'Not added',
                        style: TextStyle(
                          fontSize: 14 * scale,
                          color: _T.light,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: chips
                            .map((c) => Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10 * scale,
                                      vertical: 5 * scale),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: color.withOpacity(0.25)),
                                  ),
                                  child: Text(c,
                                      style: TextStyle(
                                        fontSize: 12 * scale,
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ))
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── WARNING BANNER ────────────────────────────────────────────────────────
  Widget _warning(String msg, double scale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFF97316), size: 18),
        SizedBox(width: 10 * scale),
        Expanded(
          child: Text(msg,
              style: TextStyle(
                  color: const Color(0xFF92400E), fontSize: 13 * scale)),
        ),
      ]),
    );
  }

  // ── COMPLETION CARD ───────────────────────────────────────────────────────
  Widget _completionCard(int pct, String msg, double scale) {
    return Container(
      padding: EdgeInsets.all(18 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_T.gStart, _T.gEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18 * scale),
        boxShadow: [
          BoxShadow(
              color: _T.primary.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile Completion',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.bold)),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale, vertical: 4 * scale),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$pct%',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(msg,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85), fontSize: 12 * scale)),
        ],
      ),
    );
  }

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  Widget _emptyState(double scale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration:
                const BoxDecoration(color: _T.soft, shape: BoxShape.circle),
            child: Icon(Icons.person_add_alt_1_rounded,
                size: 64 * scale, color: _T.primary),
          ),
          SizedBox(height: 22 * scale),
          Text('No Profile Found',
              style: TextStyle(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.bold,
                  color: _T.dark)),
          SizedBox(height: 8 * scale),
          Text('Create a profile to get started',
              style: TextStyle(fontSize: 14 * scale, color: _T.mid)),
          SizedBox(height: 28 * scale),
          ElevatedButton.icon(
            onPressed: () => _navigateToEdit(null),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                  horizontal: 28 * scale, vertical: 14 * scale),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              shadowColor: _T.primary.withOpacity(0.4),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text('Create Profile',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15 * scale)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                ref.refresh(patientProfileProvider(widget.patientId)),
            child: const Text('Retry', style: TextStyle(color: _T.primary)),
          ),
        ],
      ),
    );
  }

  // ── ERROR STATE ───────────────────────────────────────────────────────────
  Widget _errorState(Object err, dynamic provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text('$err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _T.mid)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _T.primary, foregroundColor: Colors.white),
            onPressed: () => ref.refresh(provider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ── LINKING CONTENT ───────────────────────────────────────────────────────
  Widget _linkingContent(double scale, PatientProfile profile) {
    final activeCode = ref.watch(activeInviteCodeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Invite code
        Padding(
          padding: EdgeInsets.all(16 * scale),
          child: activeCode.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Error: $e', style: const TextStyle(color: Colors.red)),
            data: (code) {
              if (code != null) {
                return Column(children: [
                  Text('Share this code with your caregiver',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _T.mid, fontSize: 13 * scale)),
                  SizedBox(height: 12 * scale),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20 * scale, vertical: 14 * scale),
                    decoration: BoxDecoration(
                      color: _T.soft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _T.accent.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          code.code,
                          style: TextStyle(
                            fontSize: 30 * scale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                            color: _T.primary,
                          ),
                        ),
                        SizedBox(width: 8 * scale),
                        IconButton(
                          icon:
                              const Icon(Icons.copy_rounded, color: _T.primary),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code.code));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Code copied to clipboard!'),
                            ));
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    'Expires in ${code.expiresAt.difference(DateTime.now()).inHours} hours',
                    style: TextStyle(
                        fontSize: 12 * scale, color: Colors.red.shade400),
                  ),
                ]);
              } else {
                return Center(
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(linkControllerProvider.notifier)
                        .generateCode(),
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('Generate Invite Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 20 * scale, vertical: 14 * scale),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                );
              }
            },
          ),
        ),

        Divider(height: 1, color: _T.soft.withOpacity(0.9)),

        // Linked caregivers
        Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Linked Caregivers',
                  style: TextStyle(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.bold,
                      color: _T.mid)),
              SizedBox(height: 10 * scale),
              ref.watch(linkedCaregiversProvider(profile.id)).when(
                    loading: () =>
                        const Center(child: LinearProgressIndicator()),
                    error: (e, _) => Text('Error: $e',
                        style: const TextStyle(color: Colors.red)),
                    data: (links) {
                      if (links.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(12 * scale),
                            child: Text(
                              'No caregivers linked yet.',
                              style: TextStyle(
                                  color: _T.light,
                                  fontSize: 14 * scale,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: links.map((link) {
                          final cp =
                              link['caregiver_profiles'] is Map<String, dynamic>
                                  ? link['caregiver_profiles']
                                      as Map<String, dynamic>
                                  : <String, dynamic>{};
                          final name =
                              cp['full_name']?.toString() ?? 'Linked Caregiver';
                          final photo = cp['profile_photo_url']?.toString();
                          final rel = cp['relationship']?.toString();
                          final phone = cp['phone_number']?.toString() ??
                              'No phone number';

                          return Container(
                            margin: EdgeInsets.only(bottom: 8 * scale),
                            padding: EdgeInsets.all(8 * scale),
                            decoration: BoxDecoration(
                              color: _T.soft.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 22 * scale,
                                backgroundColor: _T.soft,
                                backgroundImage:
                                    (photo != null && photo.isNotEmpty)
                                        ? NetworkImage(photo)
                                        : null,
                                child: (photo == null || photo.isEmpty)
                                    ? Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'C',
                                        style: const TextStyle(
                                            color: _T.primary,
                                            fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              title: Text(name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15 * scale,
                                      color: _T.dark)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (rel != null)
                                    Text(rel,
                                        style:
                                            const TextStyle(color: _T.primary)),
                                  Text(phone,
                                      style: TextStyle(fontSize: 12 * scale)),
                                ],
                              ),
                              trailing: const Icon(Icons.verified_rounded,
                                  color: _T.primary, size: 20),
                              onTap: () => _showCaregiverDialog(
                                  name, photo, rel, phone, scale),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCaregiverDialog(
      String name, String? photo, String? rel, String phone, double scale) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.all(24 * scale),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40 * scale,
              backgroundColor: _T.soft,
              backgroundImage: (photo != null && photo.isNotEmpty)
                  ? NetworkImage(photo)
                  : null,
              child: (photo == null || photo.isEmpty)
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'C',
                      style: TextStyle(
                          fontSize: 32 * scale,
                          color: _T.primary,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            SizedBox(height: 16 * scale),
            Text(name,
                style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                    color: _T.dark),
                textAlign: TextAlign.center),
            if (rel != null) ...[
              SizedBox(height: 6 * scale),
              Text(rel,
                  style: TextStyle(fontSize: 15 * scale, color: _T.primary)),
            ],
            SizedBox(height: 10 * scale),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.phone, size: 16 * scale, color: _T.mid),
              SizedBox(width: 6 * scale),
              Text(phone,
                  style: TextStyle(fontSize: 15 * scale, color: _T.mid)),
            ]),
            SizedBox(height: 24 * scale),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(vertical: 12 * scale),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HOME LOCATION ─────────────────────────────────────────────────────────
  Widget _homeLocationSection(double scale, String patientId) {
    final safeZoneAsync = ref.watch(patientSafeZoneProvider(patientId));
    final homeLocAsync = ref.watch(patientHomeLocationProvider(patientId));

    if (safeZoneAsync.value != null || homeLocAsync.value != null) {
      return const SizedBox.shrink();
    }

    return Column(children: [
      _section(
        title: 'Home Location',
        icon: Icons.home_rounded,
        grad: const [Color(0xFF7C3AED), Color(0xFF9333EA)],
        scale: scale,
        children: [
          safeZoneAsync.when(
            data: (_) => homeLocAsync.when(
              data: (_) => Padding(
                padding: EdgeInsets.all(20 * scale),
                child: Column(children: [
                  Icon(Icons.add_location_alt_outlined,
                      size: 48, color: _T.accent),
                  SizedBox(height: 12 * scale),
                  Text('Set Home Location',
                      style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.bold,
                          color: _T.dark)),
                  SizedBox(height: 6 * scale),
                  Text(
                    'Setting a home location helps caregivers know you are safe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13 * scale, color: _T.mid),
                  ),
                  SizedBox(height: 16 * scale),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToSafeZonePicker(patientId, null),
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: const Text('Set Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ]),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
      SizedBox(height: 20 * scale),
    ]);
  }

  void _navigateToSafeZonePicker(String patientId, SafeZone? zone) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SafeZonePickerScreen(
        patientId: patientId,
        initialLatitude: zone?.centerLatitude,
        initialLongitude: zone?.centerLongitude,
        initialRadiusMeters: zone?.radiusMeters.toInt(),
        existingZoneId: zone?.id,
        initialLabel: zone?.label,
      ),
    ));
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  int _age(DateTime dob) {
    final t = DateTime.now();
    int a = t.year - dob.year;
    if (t.month < dob.month || (t.month == dob.month && t.day < dob.day)) a--;
    return a;
  }

  List<Widget> _divide(List<Widget> list, Widget sep) {
    final r = <Widget>[];
    for (int i = 0; i < list.length; i++) {
      r.add(list[i]);
      if (i < list.length - 1) r.add(sep);
    }
    return r;
  }
}
