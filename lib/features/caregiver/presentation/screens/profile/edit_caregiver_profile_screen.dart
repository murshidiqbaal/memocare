import 'dart:io';

import 'package:dementia_care_app/data/models/caregiver.dart';
import 'package:dementia_care_app/providers/caregiver_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _C {
  static const Color bg = Color(0xFF0D1B2A);
  static const Color surface = Color(0xFF162032);
  static const Color surfaceAlt = Color(0xFF1C2B3E);
  static const Color surfaceHigh = Color(0xFF233347);
  static const Color border = Color(0xFF2A3F58);
  static const Color teal = Color(0xFF2DD4BF);
  static const Color blue = Color(0xFF60A5FA);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color amber = Color(0xFFFFB347);
  static const Color lavender = Color(0xFFA78BFA);
  static const Color green = Color(0xFF34D399);
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSub = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF4E687A);
  static const double rLg = 20.0;
  static const double rMd = 14.0;
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class EditCaregiverProfileScreen extends ConsumerStatefulWidget {
  final Caregiver? existingProfile;
  const EditCaregiverProfileScreen({super.key, this.existingProfile});

  @override
  ConsumerState<EditCaregiverProfileScreen> createState() =>
      _EditCaregiverProfileScreenState();
}

class _EditCaregiverProfileScreenState
    extends ConsumerState<EditCaregiverProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ─────────────────────────────────────────────────────────────
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _qualificationCtrl;
  late final TextEditingController _licenseCtrl;
  late final TextEditingController _shiftHoursCtrl;
  late final TextEditingController _experienceCtrl;

  // ── State ────────────────────────────────────────────────────────────────────
  String? _selectedRelationship;
  String? _selectedCareType;
  DateTime? _dateOfBirth;
  List<String> _languages = [];
  List<String> _certifications = [];
  List<int> _availableDays = [0, 1, 2, 3, 4];
  bool _notifEnabled = true;
  bool _emergencyAvail = true;
  String? _profilePhotoUrl;
  File? _selectedImage;
  bool _isSaving = false;
  String? _saveError;

  // ── Options ──────────────────────────────────────────────────────────────────
  static const _relationshipOpts = [
    'Son',
    'Daughter',
    'Spouse',
    'Grandchild',
    'Professional Caregiver',
    'Other',
  ];
  static const _careTypeOpts = [
    'In-Home Care',
    'Live-In Care',
    'Day Care',
    'Night Care',
    'Respite Care',
  ];
  static const _languageOpts = [
    'English',
    'Malayalam',
    'Tamil',
    'Hindi',
    'Arabic',
    'Kannada',
    'Telugu',
  ];
  static const _certOpts = [
    'CPR Certified',
    'First Aid',
    'Dementia Care',
    'Palliative Care',
    'Medication Management',
    'Mental Health First Aid',
  ];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late final AnimationController _fadeCtrl;

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;

    _fullNameCtrl = TextEditingController(text: p?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _emailCtrl = TextEditingController(text: p?.email ?? '');
    _addressCtrl = TextEditingController(text: p?.address ?? '');
    _qualificationCtrl = TextEditingController(text: p?.qualification ?? '');
    _licenseCtrl = TextEditingController(text: p?.licenseNumber ?? '');
    _shiftHoursCtrl =
        TextEditingController(text: p?.shiftHours ?? '08:00 AM – 04:00 PM');
    _experienceCtrl =
        TextEditingController(text: p?.yearsOfExperience?.toString() ?? '');

    _selectedRelationship = p?.relationship;
    _selectedCareType = p?.careType;
    _dateOfBirth = p?.dateOfBirth;
    _languages = List<String>.from(p?.languages ?? []);
    _certifications = List<String>.from(p?.certifications ?? []);
    _availableDays = List<int>.from(p?.availableDays ?? [0, 1, 2, 3, 4]);
    _notifEnabled = p?.notificationEnabled ?? true;
    _emergencyAvail = p?.emergencyAvailable ?? true;
    _profilePhotoUrl = p?.profilePhotoUrl;

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _qualificationCtrl.dispose();
    _licenseCtrl.dispose();
    _shiftHoursCtrl.dispose();
    _experienceCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Pick image ───────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => _selectedImage = File(img.path));
  }

  // ── Date picker ──────────────────────────────────────────────────────────────
  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1980),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _C.teal,
            surface: _C.surface,
            onSurface: _C.textPrimary,
          ),
          dialogBackgroundColor: _C.surface,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  // ── SAVE ─────────────────────────────────────────────────────────────────────
  // Bypasses the provider's upsert and writes directly to Supabase so we can
  // control the exact column names and get clear error messages.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null)
        throw Exception('Not authenticated. Please sign in again.');

      // 1. Upload photo ─────────────────────────────────────────────────────────
      String? photoUrl = _profilePhotoUrl;
      if (_selectedImage != null) {
        try {
          photoUrl = await ref
              .read(caregiverProfileProvider.notifier)
              .uploadPhoto(_selectedImage!);
        } catch (e) {
          debugPrint('Photo upload failed (non-fatal): $e');
        }
      }

      // 2. Build map with EXACT Supabase column names ───────────────────────────
      // ⚠️  If your table uses 'phone' instead of 'phone_number', change it here.
      final data = <String, dynamic>{
        'user_id': user.id,
        'full_name': _fullNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'relationship': _selectedRelationship,
        'notification_enabled': _notifEnabled,
        'profile_photo_url': photoUrl,

        // ── Personal ───────────────────────────────────────────────────────────
        'email': _noe(_emailCtrl.text),
        'address': _noe(_addressCtrl.text),
        'date_of_birth': _dateOfBirth?.toIso8601String(),
        'languages': _languages.isEmpty ? null : _languages,

        // ── Professional ───────────────────────────────────────────────────────
        'years_of_experience': int.tryParse(_experienceCtrl.text.trim()),
        'qualification': _noe(_qualificationCtrl.text),
        'license_number': _noe(_licenseCtrl.text),
        'certifications': _certifications.isEmpty ? null : _certifications,

        // ── Availability ───────────────────────────────────────────────────────
        'shift_hours': _noe(_shiftHoursCtrl.text),
        'care_type': _selectedCareType,
        'available_days': _availableDays.isEmpty ? null : _availableDays,
        'emergency_available': _emergencyAvail,
      }..removeWhere(
          (_, v) => v == null); // don't overwrite existing values with null

      debugPrint('[EditProfile] upserting → $data');

      // 3. Upsert — onConflict: 'user_id' updates the existing row ──────────────
      await supabase
          .from('caregiver_profiles')
          .upsert(data, onConflict: 'user_id');

      // 4. Force provider to reload so profile screen shows fresh data ──────────
      ref.invalidate(caregiverProfileProvider);

      if (mounted) {
        _showSnack('Profile saved!', _C.green);
        Navigator.pop(context);
      }
    } on PostgrestException catch (e) {
      debugPrint(
          '[EditProfile] PostgrestException → ${e.message} | code: ${e.code}');
      final msg = _pgError(e);
      setState(() => _saveError = msg);
      if (mounted) _showSnack(msg, _C.coral);
    } catch (e) {
      debugPrint('[EditProfile] error → $e');
      setState(() => _saveError = e.toString());
      if (mounted) _showSnack('Error: $e', _C.coral);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Null-on-empty helper — don't write empty strings to DB.
  String? _noe(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  /// Human-readable Postgres error messages.
  String _pgError(PostgrestException e) {
    switch (e.code) {
      case '42703':
        return 'Column not found: ${e.message}\n→ Run the SQL migration in Supabase.';
      case '23505':
        return 'Profile already exists for this user.';
      case '42501':
        return 'Permission denied — check your RLS policies.';
      case 'PGRST301':
        return 'Session expired — please sign in again.';
      default:
        return e.message;
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: _C.textPrimary, fontSize: 13)),
      backgroundColor: _C.surface,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_C.rMd),
        side: BorderSide(color: color.withOpacity(0.6)),
      ),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App bar
            SliverAppBar(
              backgroundColor: _C.bg,
              pinned: true,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _C.textPrimary, size: 20),
              ),
              title: Text(
                widget.existingProfile == null
                    ? 'Create Profile'
                    : 'Edit Profile',
                style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3),
              ),
              centerTitle: true,
            ),

            SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 36),

                      // Error banner
                      if (_saveError != null) ...[
                        _ErrorBanner(message: _saveError!),
                        const SizedBox(height: 20),
                      ],

                      _sectionLabel('Personal Information', _C.teal),
                      const SizedBox(height: 14),
                      _personalCard(),
                      const SizedBox(height: 28),

                      _sectionLabel('Professional Details', _C.blue),
                      const SizedBox(height: 14),
                      _professionalCard(),
                      const SizedBox(height: 28),

                      _sectionLabel('Availability & Shift', _C.amber),
                      const SizedBox(height: 14),
                      _availabilityCard(),
                      const SizedBox(height: 28),

                      _sectionLabel('Notifications & Preferences', _C.lavender),
                      const SizedBox(height: 14),
                      _prefsCard(),
                      const SizedBox(height: 36),

                      _buttons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar ───────────────────────────────────────────────────────────────────
  Widget _buildAvatar() {
    final hasLocal = _selectedImage != null;
    final hasNetwork = _profilePhotoUrl?.isNotEmpty == true;
    return Center(
      child: Stack(clipBehavior: Clip.none, children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _C.teal.withOpacity(0.6), width: 3),
              boxShadow: [
                BoxShadow(
                    color: _C.teal.withOpacity(0.25),
                    blurRadius: 24,
                    spreadRadius: 2)
              ],
            ),
            child: Hero(
              tag: 'caregiver_avatar',
              child: CircleAvatar(
                radius: 52,
                backgroundColor: _C.surfaceHigh,
                backgroundImage: hasLocal
                    ? FileImage(_selectedImage!) as ImageProvider
                    : hasNetwork
                        ? NetworkImage(_profilePhotoUrl!)
                        : null,
                child: (!hasLocal && !hasNetwork)
                    ? const Icon(Icons.person, size: 48, color: _C.textMuted)
                    : null,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_C.teal, _C.blue]),
                shape: BoxShape.circle,
                border: Border.all(color: _C.bg, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 15, color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Personal card ─────────────────────────────────────────────────────────────
  Widget _personalCard() => _Card(
          child: Column(children: [
        _TF(
            ctrl: _fullNameCtrl,
            label: 'Full Name',
            icon: Icons.person_rounded,
            color: _C.teal,
            validator: (v) => v?.isEmpty == true ? 'Required' : null),
        _div(),
        _TF(
            ctrl: _phoneCtrl,
            label: 'Phone Number',
            icon: Icons.phone_rounded,
            color: _C.green,
            type: TextInputType.phone,
            validator: (v) => v?.isEmpty == true ? 'Required' : null),
        _div(),
        _TF(
            ctrl: _emailCtrl,
            label: 'Email Address',
            icon: Icons.email_rounded,
            color: _C.blue,
            type: TextInputType.emailAddress),
        _div(),
        _TF(
            ctrl: _addressCtrl,
            label: 'Home Address',
            icon: Icons.location_on_rounded,
            color: _C.coral,
            maxLines: 2),
        _div(),
        _TapRow(
          label: 'Date of Birth',
          icon: Icons.cake_rounded,
          color: _C.teal,
          value: _dateOfBirth != null
              ? '${_dateOfBirth!.day.toString().padLeft(2, '0')} / '
                  '${_dateOfBirth!.month.toString().padLeft(2, '0')} / '
                  '${_dateOfBirth!.year}'
              : 'Tap to select',
          isPlaceholder: _dateOfBirth == null,
          onTap: _pickDOB,
        ),
        _div(),
        _DD<String>(
          label: 'Relationship to Patient',
          icon: Icons.family_restroom_rounded,
          color: _C.amber,
          value: _selectedRelationship,
          items: _relationshipOpts,
          onChanged: (v) => setState(() => _selectedRelationship = v),
          validator: (v) => v == null ? 'Please select' : null,
        ),
        _div(),
        _Chips(
          label: 'Languages Spoken',
          icon: Icons.language_rounded,
          color: _C.lavender,
          options: _languageOpts,
          selected: _languages,
          onChanged: (v) => setState(() => _languages = v),
        ),
      ]));

  // ── Professional card ─────────────────────────────────────────────────────────
  Widget _professionalCard() => _Card(
          child: Column(children: [
        _TF(
            ctrl: _qualificationCtrl,
            label: 'Qualification',
            icon: Icons.school_rounded,
            color: _C.blue,
            hint: 'e.g. Registered Nurse'),
        _div(),
        _TF(
            ctrl: _licenseCtrl,
            label: 'License / ID Number',
            icon: Icons.badge_rounded,
            color: _C.amber),
        _div(),
        _TF(
            ctrl: _experienceCtrl,
            label: 'Years of Experience',
            icon: Icons.work_history_rounded,
            color: _C.teal,
            type: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly]),
        _div(),
        _Chips(
          label: 'Certifications',
          icon: Icons.verified_user_rounded,
          color: _C.lavender,
          options: _certOpts,
          selected: _certifications,
          onChanged: (v) => setState(() => _certifications = v),
        ),
      ]));

  // ── Availability card ─────────────────────────────────────────────────────────
  Widget _availabilityCard() => _Card(
          child: Column(children: [
        _TF(
            ctrl: _shiftHoursCtrl,
            label: 'Shift Hours',
            icon: Icons.schedule_rounded,
            color: _C.blue,
            hint: 'e.g. 08:00 AM – 04:00 PM'),
        _div(),
        _DD<String>(
          label: 'Care Type',
          icon: Icons.home_rounded,
          color: _C.teal,
          value: _selectedCareType,
          items: _careTypeOpts,
          onChanged: (v) => setState(() => _selectedCareType = v),
        ),
        _div(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _iconBox(Icons.calendar_month_rounded, _C.amber),
              const SizedBox(width: 14),
              const Text('Available Days',
                  style: TextStyle(
                      color: _C.textSub,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final on = _availableDays.contains(i);
                return GestureDetector(
                  onTap: () => setState(() =>
                      on ? _availableDays.remove(i) : _availableDays.add(i)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: on
                          ? const LinearGradient(
                              colors: [_C.teal, _C.blue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight)
                          : null,
                      color: on ? null : _C.surfaceHigh,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: on
                          ? [
                              BoxShadow(
                                  color: _C.teal.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ]
                          : null,
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_dayLabels[i][0],
                              style: TextStyle(
                                  color: on ? Colors.white : _C.textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          Text(_dayLabels[i].substring(1),
                              style: TextStyle(
                                  color: on ? Colors.white70 : _C.textMuted,
                                  fontSize: 9)),
                        ]),
                  ),
                );
              }),
            ),
          ]),
        ),
      ]));

  // ── Preferences card ──────────────────────────────────────────────────────────
  Widget _prefsCard() => _Card(
          child: Column(children: [
        _Toggle(
          icon: Icons.notifications_active_rounded,
          color: _C.teal,
          label: 'Enable Notifications',
          subtitle: 'Receive alerts for patient activity',
          value: _notifEnabled,
          onChanged: (v) => setState(() => _notifEnabled = v),
        ),
        _div(),
        _Toggle(
          icon: Icons.emergency_rounded,
          color: _C.coral,
          label: 'Emergency Available',
          subtitle: 'Can be contacted outside shift hours',
          value: _emergencyAvail,
          onChanged: (v) => setState(() => _emergencyAvail = v),
        ),
      ]));

  // ── Buttons ───────────────────────────────────────────────────────────────────
  Widget _buttons() => Row(children: [
        Expanded(
            child: _OutlineBtn(
                label: 'Cancel', onTap: () => Navigator.pop(context))),
        const SizedBox(width: 14),
        Expanded(
            flex: 2,
            child: _GradientBtn(
                label: 'Save Profile',
                isLoading: _isSaving,
                onTap: _isSaving ? null : _saveProfile)),
      ]);

  // ── Tiny helpers ──────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, Color accent) => Row(children: [
        Container(
            width: 3,
            height: 16,
            color: accent,
            margin: const EdgeInsets.only(right: 10)),
        Text(text.toUpperCase(),
            style: const TextStyle(
                color: _C.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6)),
      ]);

  Widget _div() => const Divider(color: _C.border, height: 1, thickness: 1);

  Widget _iconBox(IconData icon, Color color) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      );
}

// ═══ Reusable widgets ═════════════════════════════════════════════════════════

// ── Error banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.coral.withOpacity(0.1),
          borderRadius: BorderRadius.circular(_C.rMd),
          border: Border.all(color: _C.coral.withOpacity(0.4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline_rounded, color: _C.coral, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: _C.coral, fontSize: 13, height: 1.5))),
        ]),
      );
}

// ── Card ──────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(_C.rLg),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ],
        ),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: child),
      );
}

// ── Text form field ───────────────────────────────────────────────────────────
class _TF extends StatelessWidget {
  const _TF({
    required this.ctrl,
    required this.label,
    required this.icon,
    required this.color,
    this.type,
    this.hint,
    this.maxLines = 1,
    this.validator,
    this.formatters,
  });
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final Color color;
  final TextInputType? type;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? formatters;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: TextFormField(
          controller: ctrl,
          keyboardType: type,
          maxLines: maxLines,
          inputFormatters: formatters,
          style: const TextStyle(color: _C.textPrimary, fontSize: 14.5),
          validator: validator,
          cursorColor: _C.teal,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: const TextStyle(color: _C.textMuted, fontSize: 13),
            labelStyle: const TextStyle(color: _C.textSub, fontSize: 13),
            prefixIcon: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9)),
                    child: Icon(icon, color: color, size: 17))),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            errorStyle: const TextStyle(color: _C.coral, fontSize: 11),
          ),
        ),
      );
}

// ── Tap / date field ──────────────────────────────────────────────────────────
class _TapRow extends StatelessWidget {
  const _TapRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.onTap,
    this.isPlaceholder = false,
  });
  final String label;
  final IconData icon;
  final Color color;
  final String value;
  final bool isPlaceholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: const TextStyle(
                          color: _C.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          color: isPlaceholder ? _C.textMuted : _C.textPrimary,
                          fontSize: 14.5,
                          fontWeight: isPlaceholder
                              ? FontWeight.w400
                              : FontWeight.w600)),
                ])),
            const Icon(Icons.chevron_right_rounded,
                color: _C.textMuted, size: 18),
          ]),
        ),
      );
}

// ── Dropdown ──────────────────────────────────────────────────────────────────
class _DD<T> extends StatelessWidget {
  const _DD({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });
  final String label;
  final IconData icon;
  final Color color;
  final T? value;
  final List<T> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: DropdownButtonFormField<T>(
          value: value,
          validator: validator,
          dropdownColor: _C.surfaceAlt,
          style: const TextStyle(color: _C.textPrimary, fontSize: 14.5),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _C.textMuted),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: _C.textSub, fontSize: 13),
            prefixIcon: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9)),
                    child: Icon(icon, color: color, size: 17))),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            errorStyle: const TextStyle(color: _C.coral, fontSize: 11),
          ),
          items: items
              .map((e) =>
                  DropdownMenuItem<T>(value: e, child: Text(e.toString())))
              .toList(),
          onChanged: onChanged,
        ),
      );
}

// ── Multi-chip selector ───────────────────────────────────────────────────────
class _Chips extends StatelessWidget {
  const _Chips({
    required this.label,
    required this.icon,
    required this.color,
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final Color color;
  final List<String> options, selected;
  final void Function(List<String>) onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    color: _C.textSub,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 12),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                final on = selected.contains(opt);
                return GestureDetector(
                  onTap: () {
                    final upd = List<String>.from(selected);
                    on ? upd.remove(opt) : upd.add(opt);
                    onChanged(upd);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: on
                          ? LinearGradient(
                              colors: [color, color.withOpacity(0.7)])
                          : null,
                      color: on ? null : _C.surfaceHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: on ? Colors.transparent : _C.border),
                      boxShadow: on
                          ? [
                              BoxShadow(
                                  color: color.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ]
                          : null,
                    ),
                    child: Text(opt,
                        style: TextStyle(
                            color: on ? Colors.white : _C.textSub,
                            fontSize: 12,
                            fontWeight:
                                on ? FontWeight.w700 : FontWeight.w500)),
                  ),
                );
              }).toList()),
        ]),
      );
}

// ── Toggle row ────────────────────────────────────────────────────────────────
class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color color;
  final String label, subtitle;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        color: _C.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(color: _C.textMuted, fontSize: 11)),
              ])),
          Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: _C.teal,
              inactiveThumbColor: _C.textMuted,
              inactiveTrackColor: _C.surfaceHigh),
        ]),
      );
}

// ── Gradient save button ──────────────────────────────────────────────────────
class _GradientBtn extends StatelessWidget {
  const _GradientBtn(
      {required this.label, required this.isLoading, required this.onTap});
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap == null ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_C.teal, _C.blue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(_C.rMd),
              boxShadow: [
                BoxShadow(
                    color: _C.teal.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4))),
          ),
        ),
      );
}

// ── Outline cancel button ─────────────────────────────────────────────────────
class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_C.rMd),
            border: Border.all(color: _C.border, width: 1.5),
          ),
          child: Center(
              child: Text(label,
                  style: const TextStyle(
                      color: _C.textSub,
                      fontSize: 15,
                      fontWeight: FontWeight.w600))),
        ),
      );
}
