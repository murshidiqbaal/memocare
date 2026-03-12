import 'dart:io';

import 'package:memocare/data/models/user/patient_profile.dart';
import 'package:memocare/features/auth/providers/auth_provider.dart';
import 'package:memocare/providers/service_providers.dart';
// import 'package:memocare/models/user/patient_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// import '../../../data/models/patient_profile.dart';
// import '../../../providers/auth_provider.dart';
// import '../../../providers/service_providers.dart';

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

// ─── SECTION CONFIG ───────────────────────────────────────────────────────────
class _SectionConfig {
  final String title;
  final IconData icon;
  final List<Color> grad;
  final String? badge;
  const _SectionConfig(this.title, this.icon, this.grad, {this.badge});
}

// ─── ANIMATED SECTION WRAPPER ─────────────────────────────────────────────────
class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final AnimationController controller;

  const _FadeSlideIn({
    required this.child,
    required this.index,
    required this.controller,
  });

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn> {
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final s = (widget.index * 0.06).clamp(0.0, 0.65);
    final e = (s + 0.35).clamp(0.0, 1.0);
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: widget.controller,
          curve: Interval(s, e, curve: Curves.easeOutCubic)),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: widget.controller,
            curve: Interval(s, e, curve: Curves.easeOutCubic)));
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ─── PRESS SCALE WIDGET ───────────────────────────────────────────────────────
class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Press({required this.child, this.onTap});

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) {
          _c.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _c.reverse(),
        child: ScaleTransition(scale: _s, child: widget.child),
      );
}

// ─── MAIN SCREEN ─────────────────────────────────────────────────────────────
class EditPatientProfileScreen extends ConsumerStatefulWidget {
  final PatientProfile? existingProfile;
  final String? patientId;

  const EditPatientProfileScreen({
    super.key,
    this.existingProfile,
    this.patientId,
  });

  @override
  ConsumerState<EditPatientProfileScreen> createState() =>
      _EditPatientProfileScreenState();
}

class _EditPatientProfileScreenState
    extends ConsumerState<EditPatientProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  late AnimationController _masterCtrl;
  late AnimationController _saveCtrl;
  late Animation<double> _savePulse;

  // ── Controllers ─────────────────────────────────────────────────────────
  // Personal
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;

  // Emergency & Medical
  late TextEditingController _emergencyNameCtrl;
  late TextEditingController _emergencyPhoneCtrl;
  late TextEditingController _medicalNotesCtrl;

  // Hobbies & Interests
  late TextEditingController _favouritePastimeCtrl;
  late TextEditingController _hobbyInputCtrl;
  List<String> _hobbies = [];

  // Favourite Things
  late TextEditingController _favouriteFoodCtrl;
  late TextEditingController _favouriteDrinkCtrl;
  late TextEditingController _favouriteMusicCtrl;
  late TextEditingController _favouriteShowCtrl;
  late TextEditingController _favouritePlaceCtrl;

  // Daily Routine
  late TextEditingController _wakeUpTimeCtrl;
  late TextEditingController _bedTimeCtrl;
  late TextEditingController _mealPrefsCtrl;
  late TextEditingController _exerciseRoutineCtrl;
  late TextEditingController _religiousPracticesCtrl;
  late TextEditingController _napTimeCtrl;

  // Language & Communication
  late TextEditingController _preferredLanguageCtrl;
  late TextEditingController _communicationStyleCtrl;
  late TextEditingController _triggersCtrl;
  late TextEditingController _calmingStrategiesCtrl;
  late TextEditingController _importantPeopleCtrl;

  // ── State ────────────────────────────────────────────────────────────────
  DateTime? _selectedDob;
  String? _selectedGender;
  String? _selectedIndoorOutdoor;
  File? _selectedImage;
  bool _isSaving = false;

  // Section expand state
  final Map<int, bool> _expanded = {
    0: true,
    1: true,
    2: false,
    3: false,
    4: false,
    5: false,
    6: false
  };

  // ── Section configs ──────────────────────────────────────────────────────
  static const _sections = [
    _SectionConfig('Personal Information', Icons.person_rounded,
        [Color(0xFF7C3AED), Color(0xFF9333EA)]),
    _SectionConfig('Emergency & Medical', Icons.local_hospital_rounded,
        [Color(0xFFDC2626), Color(0xFFEF4444)]),
    _SectionConfig('Hobbies & Interests', Icons.favorite_rounded,
        [Color(0xFFEC4899), Color(0xFFF472B6)],
        badge: 'Optional'),
    _SectionConfig('Favourite Things', Icons.star_rounded,
        [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        badge: 'Optional'),
    _SectionConfig('Daily Routine', Icons.schedule_rounded,
        [Color(0xFF0891B2), Color(0xFF06B6D4)],
        badge: 'Optional'),
    _SectionConfig(
        'Language & Communication',
        Icons.chat_bubble_outline_rounded,
        [Color(0xFF0D9488), Color(0xFF14B8A6)],
        badge: 'Optional'),
  ];

  @override
  void initState() {
    super.initState();
    _masterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward();

    _saveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _savePulse = Tween<double>(begin: 1.0, end: 1.04)
        .animate(CurvedAnimation(parent: _saveCtrl, curve: Curves.easeInOut));

    _initControllers();
    _loadExistingData();
  }

  void _initControllers() {
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _emergencyNameCtrl = TextEditingController();
    _emergencyPhoneCtrl = TextEditingController();
    _medicalNotesCtrl = TextEditingController();
    _favouritePastimeCtrl = TextEditingController();
    _hobbyInputCtrl = TextEditingController();
    _favouriteFoodCtrl = TextEditingController();
    _favouriteDrinkCtrl = TextEditingController();
    _favouriteMusicCtrl = TextEditingController();
    _favouriteShowCtrl = TextEditingController();
    _favouritePlaceCtrl = TextEditingController();
    _wakeUpTimeCtrl = TextEditingController();
    _bedTimeCtrl = TextEditingController();
    _mealPrefsCtrl = TextEditingController();
    _exerciseRoutineCtrl = TextEditingController();
    _religiousPracticesCtrl = TextEditingController();
    _napTimeCtrl = TextEditingController();
    _preferredLanguageCtrl = TextEditingController();
    _communicationStyleCtrl = TextEditingController();
    _triggersCtrl = TextEditingController();
    _calmingStrategiesCtrl = TextEditingController();
    _importantPeopleCtrl = TextEditingController();
  }

  void _loadExistingData() {
    final p = widget.existingProfile;
    if (p == null) return;

    _nameCtrl.text = p.fullName ?? '';
    _phoneCtrl.text = p.phoneNumber ?? '';
    _addressCtrl.text = p.address ?? '';
    _emergencyNameCtrl.text = p.emergencyContactName ?? '';
    _emergencyPhoneCtrl.text = p.emergencyContactPhone ?? '';
    _medicalNotesCtrl.text = p.medicalNotes ?? '';
    _favouritePastimeCtrl.text = p.favouritePastime ?? '';
    _hobbies = List<String>.from(p.hobbies ?? []);
    _favouriteFoodCtrl.text = p.favouriteFood ?? '';
    _favouriteDrinkCtrl.text = p.favouriteDrink ?? '';
    _favouriteMusicCtrl.text = p.favouriteMusic ?? '';
    _favouriteShowCtrl.text = p.favouriteShow ?? '';
    _favouritePlaceCtrl.text = p.favouritePlace ?? '';
    _wakeUpTimeCtrl.text = p.wakeUpTime ?? '';
    _bedTimeCtrl.text = p.bedTime ?? '';
    _mealPrefsCtrl.text = p.mealPreferences ?? '';
    _exerciseRoutineCtrl.text = p.exerciseRoutine ?? '';
    _religiousPracticesCtrl.text = p.religiousPractices ?? '';
    _napTimeCtrl.text = p.napTime ?? '';
    _preferredLanguageCtrl.text = p.preferredLanguage ?? '';
    _communicationStyleCtrl.text = p.communicationStyle ?? '';
    _triggersCtrl.text = p.triggers ?? '';
    _calmingStrategiesCtrl.text = p.calmingStrategies ?? '';
    _importantPeopleCtrl.text = p.importantPeople ?? '';
    _selectedDob = p.dateOfBirth;
    _selectedGender = p.gender;
    _selectedIndoorOutdoor = p.indoorOutdoorPref;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _masterCtrl.dispose();
    _saveCtrl.dispose();
    for (final c in [
      _nameCtrl,
      _phoneCtrl,
      _addressCtrl,
      _emergencyNameCtrl,
      _emergencyPhoneCtrl,
      _medicalNotesCtrl,
      _favouritePastimeCtrl,
      _hobbyInputCtrl,
      _favouriteFoodCtrl,
      _favouriteDrinkCtrl,
      _favouriteMusicCtrl,
      _favouriteShowCtrl,
      _favouritePlaceCtrl,
      _wakeUpTimeCtrl,
      _bedTimeCtrl,
      _mealPrefsCtrl,
      _exerciseRoutineCtrl,
      _religiousPracticesCtrl,
      _napTimeCtrl,
      _preferredLanguageCtrl,
      _communicationStyleCtrl,
      _triggersCtrl,
      _calmingStrategiesCtrl,
      _importantPeopleCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Image Picker ─────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  // ── Time Picker ───────────────────────────────────────────────────────────
  Future<void> _pickTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = ctrl.text.isNotEmpty && parts.length == 2
        ? TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 8,
            minute: int.tryParse(parts[1]) ?? 0)
        : const TimeOfDay(hour: 8, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _T.primary),
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      final ap = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final h12 = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      ctrl.text = '${h12.toString().padLeft(2, '0')}:$m $ap';
      setState(() {});
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Please fill in all required fields'),
          ]),
          backgroundColor: Colors.red.shade500,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final user = ref.read(currentUserProvider);
      final userId = widget.patientId ?? user?.id;
      if (userId == null) throw Exception('User ID not found');

      final updatedProfile = PatientProfile(
        id: widget.existingProfile?.id ??
            userId, // Keep existing ID or fallback
        userId: userId, // Ensure userId is always set for RLS
        // Personal
        fullName: _nameCtrl.text.trim(),
        phoneNumber: _n(_phoneCtrl),
        address: _n(_addressCtrl),
        dateOfBirth: _selectedDob,
        gender: _selectedGender,
        // Emergency
        emergencyContactName: _n(_emergencyNameCtrl),
        emergencyContactPhone: _n(_emergencyPhoneCtrl),
        medicalNotes: _n(_medicalNotesCtrl),
        // Hobbies
        hobbies: _hobbies.isEmpty ? null : _hobbies,
        favouritePastime: _n(_favouritePastimeCtrl),
        indoorOutdoorPref: _selectedIndoorOutdoor,
        // Favourite Things
        favouriteFood: _n(_favouriteFoodCtrl),
        favouriteDrink: _n(_favouriteDrinkCtrl),
        favouriteMusic: _n(_favouriteMusicCtrl),
        favouriteShow: _n(_favouriteShowCtrl),
        favouritePlace: _n(_favouritePlaceCtrl),
        // Routine
        wakeUpTime: _n(_wakeUpTimeCtrl),
        bedTime: _n(_bedTimeCtrl),
        mealPreferences: _n(_mealPrefsCtrl),
        exerciseRoutine: _n(_exerciseRoutineCtrl),
        religiousPractices: _n(_religiousPracticesCtrl),
        napTime: _n(_napTimeCtrl),
        // Language
        preferredLanguage: _n(_preferredLanguageCtrl),
        communicationStyle: _n(_communicationStyleCtrl),
        triggers: _n(_triggersCtrl),
        calmingStrategies: _n(_calmingStrategiesCtrl),
        importantPeople: _n(_importantPeopleCtrl),
        // Meta
        profileImageUrl: widget.existingProfile?.profileImageUrl,
        createdAt: widget.existingProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(patientProfileRepositoryProvider);
      await repo.updateProfile(updatedProfile);

      if (_selectedImage != null) {
        final url =
            await repo.uploadProfileImage(updatedProfile.id, _selectedImage!);
        if (url != null) {
          await repo
              .updateProfile(updatedProfile.copyWith(profileImageUrl: url));
        }
      }

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Profile saved successfully!',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade500,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // null if empty
  String? _n(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final isNewProfile = widget.existingProfile == null;

    return Scaffold(
      backgroundColor: _T.bg,
      body: Stack(children: [
        NestedScrollView(
          controller: _scrollCtrl,
          headerSliverBuilder: (_, __) =>
              [_buildSliverAppBar(isNewProfile, scale)],
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  16 * scale, 20 * scale, 16 * scale, 120 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildAllSections(scale, isNewProfile),
              ),
            ),
          ),
        ),

        // ── Floating save button ──
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildSaveBar(scale, isNewProfile),
        ),

        // ── Saving overlay ──
        if (_isSaving) _buildSavingOverlay(),
      ]),
    );
  }

  // ── SLIVER APP BAR ────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(bool isNew, double scale) {
    return SliverAppBar(
      expandedHeight: 230 * scale,
      pinned: true,
      stretch: true,
      backgroundColor: _T.gStart,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        isNew ? 'Create Profile' : 'Edit Profile',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: TextButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            ),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
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
            Positioned(top: -40, right: -40, child: _blob(180, 0.07)),
            Positioned(bottom: 20, left: -30, child: _blob(120, 0.05)),
            Positioned(top: 80, right: 80, child: _blob(60, 0.04)),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 16 * scale),
                  _buildAvatarSection(scale),
                  SizedBox(height: 10 * scale),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutBack,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14 * scale, vertical: 5 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Text(
                        isNew ? '✨ New Patient Profile' : '✏️ Editing Profile',
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _blob(double size, double op) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(op),
        ),
      );

  // ── AVATAR ────────────────────────────────────────────────────────────────
  Widget _buildAvatarSection(double scale) {
    final userId = widget.patientId ?? ref.read(currentUserProvider)?.id;
    return _Press(
      onTap: _pickImage,
      child: Stack(alignment: Alignment.center, children: [
        Hero(
          tag: 'patient_avatar_${userId ?? "new"}',
          child: Container(
            width: 100 * scale,
            height: 100 * scale,
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
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : widget.existingProfile?.profileImageUrl != null
                      ? Image.network(
                          widget.existingProfile!.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _avatarPlaceholder(scale),
                        )
                      : _avatarPlaceholder(scale),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 32 * scale,
              height: 32 * scale,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _T.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.camera_alt_rounded,
                  color: _T.primary, size: 16 * scale),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _avatarPlaceholder(double scale) => Container(
        color: _T.soft,
        child: Icon(Icons.person_rounded, size: 56 * scale, color: _T.accent),
      );

  // ── ALL SECTIONS ──────────────────────────────────────────────────────────
  List<Widget> _buildAllSections(double scale, bool isNew) {
    final List<Widget> widgets = [];
    int idx = 0;

    // Progress chips at the top
    widgets.add(_FadeSlideIn(
      index: idx++,
      controller: _masterCtrl,
      child: _buildProgressChips(scale),
    ));
    widgets.add(SizedBox(height: 20 * scale));

    // Section 0: Personal Info
    widgets.add(_FadeSlideIn(
      index: idx++,
      controller: _masterCtrl,
      child: _buildCollapsibleSection(
        0,
        scale,
        children: _buildPersonalFields(scale),
      ),
    ));
    widgets.add(SizedBox(height: 16 * scale));

    // Section 1: Emergency & Medical
    widgets.add(_FadeSlideIn(
      index: idx++,
      controller: _masterCtrl,
      child: _buildCollapsibleSection(
        1,
        scale,
        children: _buildEmergencyFields(scale),
      ),
    ));
    widgets.add(SizedBox(height: 16 * scale));

    // Section 2: Hobbies
    widgets.add(_FadeSlideIn(
      index: idx++,
      controller: _masterCtrl,
      child: _buildCollapsibleSection(
        2,
        scale,
        children: _buildHobbiesFields(scale),
      ),
    ));
    widgets.add(SizedBox(height: 16 * scale));

    // Section 3: Favourite Things
    widgets.add(_FadeSlideIn(
      index: idx++,
      controller: _masterCtrl,
      child: _buildCollapsibleSection(
        3,
        scale,
        children: _buildFavouriteFields(scale),
      ),
    ));
    widgets.add(SizedBox(height: 16 * scale));

    // Section 4: Daily Routine
    widgets.add(_FadeSlideIn(
      index: idx++,
      controller: _masterCtrl,
      child: _buildCollapsibleSection(
        4,
        scale,
        children: _buildRoutineFields(scale),
      ),
    ));
    widgets.add(SizedBox(height: 16 * scale));

    // Section 5: Language & Communication
    widgets.add(_FadeSlideIn(
      index: idx++,
      controller: _masterCtrl,
      child: _buildCollapsibleSection(
        5,
        scale,
        children: _buildLanguageFields(scale),
      ),
    ));
    widgets.add(SizedBox(height: 16 * scale));

    return widgets;
  }

  // ── PROGRESS CHIPS ────────────────────────────────────────────────────────
  Widget _buildProgressChips(double scale) {
    final filled = [
      _nameCtrl.text.isNotEmpty,
      _emergencyNameCtrl.text.isNotEmpty,
      _hobbies.isNotEmpty,
      _favouriteFoodCtrl.text.isNotEmpty,
      _wakeUpTimeCtrl.text.isNotEmpty,
      _preferredLanguageCtrl.text.isNotEmpty,
    ];
    final count = filled.where((v) => v).length;
    final pct = ((count / filled.length) * 100).round();

    final labels = [
      'Personal',
      'Emergency',
      'Hobbies',
      'Favourites',
      'Routine',
      'Language'
    ];
    final grads = [
      [const Color(0xFF7C3AED), const Color(0xFF9333EA)],
      [const Color(0xFFDC2626), const Color(0xFFEF4444)],
      [const Color(0xFFEC4899), const Color(0xFFF472B6)],
      [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
      [const Color(0xFF0891B2), const Color(0xFF06B6D4)],
      [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
    ];

    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18 * scale),
        boxShadow: [
          BoxShadow(
            color: _T.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile Completeness',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13 * scale,
                      color: _T.dark)),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 10 * scale, vertical: 3 * scale),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_T.gStart, _T.gEnd]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$pct%',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12 * scale)),
              ),
            ],
          ),
          SizedBox(height: 10 * scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: _T.soft,
              valueColor: const AlwaysStoppedAnimation<Color>(_T.primary),
            ),
          ),
          SizedBox(height: 12 * scale),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(labels.length, (i) {
              final done = filled[i];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: EdgeInsets.symmetric(
                    horizontal: 10 * scale, vertical: 5 * scale),
                decoration: BoxDecoration(
                  gradient: done ? LinearGradient(colors: grads[i]) : null,
                  color: done ? null : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    done ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 12 * scale,
                    color: done ? Colors.white : _T.light,
                  ),
                  SizedBox(width: 4 * scale),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11 * scale,
                      fontWeight: FontWeight.w600,
                      color: done ? Colors.white : _T.light,
                    ),
                  ),
                ]),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── COLLAPSIBLE SECTION ───────────────────────────────────────────────────
  Widget _buildCollapsibleSection(int sectionIdx, double scale,
      {required List<Widget> children}) {
    final cfg = _sections[sectionIdx];
    final isOpen = _expanded[sectionIdx] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scale),
        boxShadow: [
          BoxShadow(
            color: cfg.grad.first.withOpacity(isOpen ? 0.12 : 0.06),
            blurRadius: isOpen ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20 * scale),
        child: Column(
          children: [
            // Header (always visible, tappable)
            _Press(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _expanded[sectionIdx] = !isOpen);
              },
              child: Container(
                padding: EdgeInsets.all(16 * scale),
                decoration: BoxDecoration(
                  gradient: isOpen
                      ? LinearGradient(
                          colors: [
                            cfg.grad.first.withOpacity(0.08),
                            cfg.grad.last.withOpacity(0.04),
                          ],
                        )
                      : null,
                  border: isOpen
                      ? Border(
                          bottom: BorderSide(
                            color: cfg.grad.first.withOpacity(0.12),
                          ),
                        )
                      : null,
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: cfg.grad),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: cfg.grad.first.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child:
                        Icon(cfg.icon, color: Colors.white, size: 16 * scale),
                  ),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cfg.title,
                            style: TextStyle(
                                fontSize: 15 * scale,
                                fontWeight: FontWeight.bold,
                                color: _T.dark)),
                        if (cfg.badge != null)
                          Text(cfg.badge!,
                              style: TextStyle(
                                  fontSize: 10 * scale,
                                  color: cfg.grad.first,
                                  fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cfg.grad.first.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: cfg.grad.first, size: 18 * scale),
                    ),
                  ),
                ]),
              ),
            ),

            // Body — animated expand/collapse
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: EdgeInsets.all(16 * scale),
                child: Column(children: children),
              ),
              crossFadeState:
                  isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 320),
              sizeCurve: Curves.easeInOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  // ── PERSONAL FIELDS ───────────────────────────────────────────────────────
  List<Widget> _buildPersonalFields(double scale) => [
        _field('Full Name *', _nameCtrl, scale,
            icon: Icons.badge_outlined, color: _T.primary, required: true),
        _datePicker(scale),
        _genderPicker(scale),
        _field('Phone Number', _phoneCtrl, scale,
            icon: Icons.phone_outlined,
            color: const Color(0xFF10B981),
            keyboard: TextInputType.phone),
        _field('Home Address', _addressCtrl, scale,
            icon: Icons.location_on_outlined,
            color: const Color(0xFFF59E0B),
            maxLines: 2),
      ];

  // ── EMERGENCY FIELDS ──────────────────────────────────────────────────────
  List<Widget> _buildEmergencyFields(double scale) => [
        _infoBox(
          'This information is critical for emergencies. Please fill accurately.',
          Icons.info_outline_rounded,
          const Color(0xFFFFF7ED),
          const Color(0xFFF97316),
          scale,
        ),
        _field('Emergency Contact Name', _emergencyNameCtrl, scale,
            icon: Icons.contact_emergency_outlined,
            color: const Color(0xFFDC2626)),
        _field('Emergency Contact Phone', _emergencyPhoneCtrl, scale,
            icon: Icons.phone_in_talk_outlined,
            color: const Color(0xFFEA580C),
            keyboard: TextInputType.phone),
        _field('Medical Notes', _medicalNotesCtrl, scale,
            icon: Icons.medical_services_outlined,
            color: const Color(0xFF2563EB),
            maxLines: 4,
            hint: 'Allergies, medications, conditions, doctor names...'),
      ];

  // ── HOBBIES FIELDS ────────────────────────────────────────────────────────
  List<Widget> _buildHobbiesFields(double scale) => [
        // Chip tag input
        _buildChipInput(scale),
        _field('Favourite Pastime / Craft', _favouritePastimeCtrl, scale,
            icon: Icons.brush_outlined,
            color: const Color(0xFFF59E0B),
            hint: 'e.g. Knitting, Painting, Reading'),
        _buildIndoorOutdoorPicker(scale),
      ];

  // Chip tag input widget
  Widget _buildChipInput(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText('Activities & Hobbies', const Color(0xFFEC4899), scale),
        SizedBox(height: 8 * scale),
        if (_hobbies.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _hobbies
                .asMap()
                .entries
                .map((e) => TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + e.key * 50),
                      curve: Curves.easeOutBack,
                      builder: (_, v, child) =>
                          Transform.scale(scale: v, child: child),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10 * scale, vertical: 6 * scale),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFFEC4899),
                            Color(0xFFF472B6),
                          ]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(e.value,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12 * scale,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(width: 4 * scale),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _hobbies.removeAt(e.key)),
                            child: Icon(Icons.close_rounded,
                                size: 14 * scale, color: Colors.white),
                          ),
                        ]),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 10 * scale),
        ],
        Row(children: [
          Expanded(
            child: _rawField(
              controller: _hobbyInputCtrl,
              hint: 'Add hobby (e.g. Gardening)',
              icon: Icons.sports_soccer_outlined,
              color: const Color(0xFFEC4899),
              scale: scale,
              onSubmit: (_) => _addHobby(),
            ),
          ),
          SizedBox(width: 8 * scale),
          _Press(
            onTap: _addHobby,
            child: Container(
              padding: EdgeInsets.all(14 * scale),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFF472B6)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.add_rounded,
                  color: Colors.white, size: 18 * scale),
            ),
          ),
        ]),
        SizedBox(height: 16 * scale),
      ],
    );
  }

  void _addHobby() {
    final val = _hobbyInputCtrl.text.trim();
    if (val.isNotEmpty && !_hobbies.contains(val)) {
      HapticFeedback.selectionClick();
      setState(() {
        _hobbies.add(val);
        _hobbyInputCtrl.clear();
      });
    }
  }

  Widget _buildIndoorOutdoorPicker(double scale) {
    const opts = ['Mostly Indoor', 'Mostly Outdoor', 'Both'];
    const icons = [
      Icons.home_outlined,
      Icons.park_outlined,
      Icons.compare_arrows_rounded,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText(
            'Outdoor / Indoor Preference', const Color(0xFF10B981), scale),
        SizedBox(height: 8 * scale),
        Row(
          children: List.generate(opts.length, (i) {
            final selected = _selectedIndoorOutdoor == opts[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: i < opts.length - 1 ? 6.0 * scale : 0),
                child: _Press(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() =>
                        _selectedIndoorOutdoor = selected ? null : opts[i]);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.symmetric(
                        vertical: 12 * scale, horizontal: 6 * scale),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(colors: [
                              Color(0xFF10B981),
                              Color(0xFF34D399),
                            ])
                          : null,
                      color: selected ? null : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? null
                          : Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icons[i],
                            size: 18 * scale,
                            color: selected ? Colors.white : _T.light),
                        SizedBox(height: 4 * scale),
                        Text(
                          opts[i].replaceAll('Mostly ', ''),
                          style: TextStyle(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : _T.mid,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 16 * scale),
      ],
    );
  }

  // ── FAVOURITE FIELDS ──────────────────────────────────────────────────────
  List<Widget> _buildFavouriteFields(double scale) => [
        _field('Favourite Food / Snack', _favouriteFoodCtrl, scale,
            icon: Icons.restaurant_outlined,
            color: const Color(0xFFF59E0B),
            hint: 'e.g. Rice porridge, Biscuits'),
        _field('Favourite Drink', _favouriteDrinkCtrl, scale,
            icon: Icons.local_cafe_outlined,
            color: const Color(0xFF92400E),
            hint: 'e.g. Masala tea, Buttermilk'),
        _field('Favourite Music / Artist', _favouriteMusicCtrl, scale,
            icon: Icons.music_note_outlined,
            color: const Color(0xFF7C3AED),
            hint: 'e.g. Old Malayalam film songs'),
        _field('Favourite TV Show / Movie', _favouriteShowCtrl, scale,
            icon: Icons.tv_outlined,
            color: const Color(0xFF2563EB),
            hint: 'e.g. Mahabharatham, old serials'),
        _field('Favourite Place / Memory', _favouritePlaceCtrl, scale,
            icon: Icons.place_outlined,
            color: const Color(0xFF10B981),
            hint: 'e.g. Home village, temple visits',
            maxLines: 2),
      ];

  // ── ROUTINE FIELDS ────────────────────────────────────────────────────────
  List<Widget> _buildRoutineFields(double scale) => [
        _timePicker('Wake Up Time', _wakeUpTimeCtrl, Icons.wb_sunny_outlined,
            const Color(0xFFF59E0B), scale),
        _timePicker('Bedtime', _bedTimeCtrl, Icons.bedtime_outlined,
            const Color(0xFF6366F1), scale),
        _timePicker('Nap / Rest Time', _napTimeCtrl,
            Icons.airline_seat_flat_outlined, const Color(0xFF8B5CF6), scale),
        _field('Meal Preferences', _mealPrefsCtrl, scale,
            icon: Icons.lunch_dining_outlined,
            color: const Color(0xFF10B981),
            hint: 'e.g. Vegetarian, soft foods, no spice',
            maxLines: 2),
        _field('Exercise / Walk Routine', _exerciseRoutineCtrl, scale,
            icon: Icons.directions_walk_outlined,
            color: const Color(0xFF059669),
            hint: 'e.g. Morning walk 7 AM, 20 mins'),
        _field('Religious / Cultural Practices', _religiousPracticesCtrl, scale,
            icon: Icons.volunteer_activism_outlined,
            color: const Color(0xFF7C3AED),
            hint: 'e.g. Morning prayer, fasting days',
            maxLines: 2),
      ];

  // ── LANGUAGE FIELDS ───────────────────────────────────────────────────────
  List<Widget> _buildLanguageFields(double scale) => [
        _field('Preferred Language', _preferredLanguageCtrl, scale,
            icon: Icons.language_outlined,
            color: const Color(0xFF0D9488),
            hint: 'e.g. Malayalam, English'),
        _field('Communication Style', _communicationStyleCtrl, scale,
            icon: Icons.record_voice_over_outlined,
            color: const Color(0xFF0891B2),
            hint: 'e.g. Speaks slowly, uses gestures',
            maxLines: 2),
        _field('Triggers to Avoid', _triggersCtrl, scale,
            icon: Icons.warning_amber_outlined,
            color: const Color(0xFFDC2626),
            hint: 'e.g. Loud noise, strangers, darkness',
            maxLines: 2),
        _field('Calming Strategies', _calmingStrategiesCtrl, scale,
            icon: Icons.spa_outlined,
            color: const Color(0xFF10B981),
            hint: 'e.g. Soft music, holding hand, prayer',
            maxLines: 2),
        _field('Important People They Remember', _importantPeopleCtrl, scale,
            icon: Icons.people_outline_rounded,
            color: const Color(0xFFEC4899),
            hint: 'e.g. Daughter Priya, son Arun, neighbour Raju',
            maxLines: 3),
      ];

  // ── FIELD BUILDERS ────────────────────────────────────────────────────────
  Widget _field(
    String label,
    TextEditingController ctrl,
    double scale, {
    required IconData icon,
    required Color color,
    TextInputType? keyboard,
    int maxLines = 1,
    String? hint,
    bool required = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14 * scale),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
            fontSize: 14.5 * scale,
            color: _T.dark,
            fontWeight: FontWeight.w500),
        decoration: _inputDeco(label, icon, color, hint, scale),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? 'This field is required'
                : null
            : null,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _rawField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    required double scale,
    Function(String)? onSubmit,
  }) {
    return TextFormField(
      controller: controller,
      onFieldSubmitted: onSubmit,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(fontSize: 14 * scale, color: _T.dark),
      decoration: _inputDeco(hint, icon, color, null, scale),
    );
  }

  InputDecoration _inputDeco(
      String label, IconData icon, Color color, String? hint, double scale) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
          color: color.withOpacity(0.8),
          fontSize: 13 * scale,
          fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: _T.light, fontSize: 13 * scale),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16 * scale),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFB),
      contentPadding:
          EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 14 * scale),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * scale),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * scale),
        borderSide: BorderSide(color: const Color(0xFFE5E7EB), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * scale),
        borderSide: BorderSide(color: color, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * scale),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * scale),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _datePicker(double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14 * scale),
      child: _Press(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDob ?? DateTime(1950),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(primary: _T.primary),
              ),
              child: child!,
            ),
          );
          if (date != null) setState(() => _selectedDob = date);
        },
        child: InputDecorator(
          decoration: _inputDeco('Date of Birth', Icons.calendar_today_outlined,
              _T.primary, null, scale),
          child: Text(
            _selectedDob == null
                ? 'Select Date'
                : DateFormat('dd MMM yyyy').format(_selectedDob!),
            style: TextStyle(
              fontSize: 14.5 * scale,
              color: _selectedDob == null ? _T.light : _T.dark,
              fontWeight:
                  _selectedDob != null ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderPicker(double scale) {
    const opts = ['Male', 'Female', 'Other'];
    const icons = [
      Icons.male_rounded,
      Icons.female_rounded,
      Icons.transgender_rounded,
    ];
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText('Gender', _T.primary, scale),
        SizedBox(height: 8 * scale),
        Row(
          children: List.generate(opts.length, (i) {
            final sel = _selectedGender == opts[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: i < opts.length - 1 ? 8.0 * scale : 0),
                child: _Press(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedGender = sel ? null : opts[i]);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.symmetric(vertical: 12 * scale),
                    decoration: BoxDecoration(
                      color: sel
                          ? colors[i].withOpacity(0.12)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? colors[i] : const Color(0xFFE5E7EB),
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icons[i],
                            size: 20 * scale,
                            color: sel ? colors[i] : _T.light),
                        SizedBox(height: 4 * scale),
                        Text(opts[i],
                            style: TextStyle(
                                fontSize: 12 * scale,
                                color: sel ? colors[i] : _T.mid,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 14 * scale),
      ],
    );
  }

  Widget _timePicker(String label, TextEditingController ctrl, IconData icon,
      Color color, double scale) {
    final hasVal = ctrl.text.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: 14 * scale),
      child: _Press(
        onTap: () => _pickTime(ctrl),
        child: InputDecorator(
          decoration: _inputDeco(label, icon, color, 'Tap to set', scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasVal ? ctrl.text : 'Tap to set',
                style: TextStyle(
                  fontSize: 14.5 * scale,
                  color: hasVal ? _T.dark : _T.light,
                  fontWeight: hasVal ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (hasVal)
                GestureDetector(
                  onTap: () => setState(() => ctrl.clear()),
                  child: Icon(Icons.close_rounded,
                      size: 16 * scale, color: _T.light),
                )
              else
                Icon(Icons.access_time_rounded,
                    size: 16 * scale, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelText(String text, Color color, double scale) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12 * scale,
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _infoBox(
      String text, IconData icon, Color bg, Color accent, double scale) {
    return Container(
      margin: EdgeInsets.only(bottom: 14 * scale),
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: accent),
        SizedBox(width: 8 * scale),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 12 * scale,
                  color: accent,
                  fontWeight: FontWeight.w500,
                  height: 1.4)),
        ),
      ]),
    );
  }

  // ── SAVE BAR ──────────────────────────────────────────────────────────────
  Widget _buildSaveBar(double scale, bool isNew) {
    return Container(
      padding:
          EdgeInsets.fromLTRB(16 * scale, 12 * scale, 16 * scale, 28 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _T.primary.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _savePulse,
        builder: (_, child) => Transform.scale(
          scale: _isSaving ? 1.0 : _savePulse.value,
          child: child,
        ),
        child: _Press(
          onTap: _isSaving ? null : _saveProfile,
          child: Container(
            height: 54 * scale,
            decoration: BoxDecoration(
              gradient: _isSaving
                  ? const LinearGradient(
                      colors: [Color(0xFF9CA3AF), Color(0xFF9CA3AF)])
                  : const LinearGradient(
                      colors: [_T.gStart, _T.gEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _isSaving
                  ? []
                  : [
                      BoxShadow(
                        color: _T.primary.withOpacity(0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Center(
              child: _isSaving
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Saving...',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          isNew ? 'CREATE PROFILE' : 'SAVE CHANGES',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── SAVING OVERLAY ────────────────────────────────────────────────────────
  Widget _buildSavingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.35),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _T.primary.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_T.gStart, _T.gEnd]),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              ),
              const SizedBox(height: 20),
              const Text('Saving Profile',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: _T.dark)),
              const SizedBox(height: 6),
              const Text('Please wait...',
                  style: TextStyle(color: _T.mid, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
