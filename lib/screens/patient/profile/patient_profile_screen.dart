import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/profile_completion_helper.dart';
import '../../../data/models/patient_profile.dart';
import '../../../features/linking/presentation/controllers/link_controller.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_photo_provider.dart'; // Ensure this key provider is imported
import '../../../widgets/editable_avatar.dart'; // Added
import 'edit_patient_profile_screen.dart';
import 'viewmodels/patient_profile_viewmodel.dart';

/// View-only Patient Profile Screen with Hero Animation and Profile Completion
/// Navigates to EditPatientProfileScreen for editing
class PatientProfileScreen extends ConsumerStatefulWidget {
  final String? patientId;
  const PatientProfileScreen({super.key, this.patientId});

  @override
  ConsumerState<PatientProfileScreen> createState() =>
      _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _navigateToEdit(PatientProfile? profile) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditPatientProfileScreen(
          existingProfile: profile,
          patientId: widget.patientId,
        ),
      ),
    );

    // Refresh profile if edit was successful
    if (result == true && mounted) {
      final provider = widget.patientId != null
          ? patientMonitoringProvider(widget.patientId!)
          : patientProfileProvider;
      ref.invalidate(provider);
    }
  }

  Future<void> _signOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.patientId != null
        ? patientMonitoringProvider(widget.patientId!)
        : patientProfileProvider;

    final profileState = ref.watch(provider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final isCaregiver = userProfile?.role == 'caregiver';

    // Calculate scale factor for responsive UI
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title:
            Text(widget.patientId != null ? 'Patient Profile' : 'My Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isCaregiver)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profile',
              onPressed: () => _navigateToEdit(profileState.value),
            ),
        ],
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No profile found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToEdit(null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Profile'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.refresh(provider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Calculate profile completion
          final completion =
              ProfileCompletionHelper.calculateCompletion(profile);
          final completionMessage =
              ProfileCompletionHelper.getCompletionMessage(completion);

          return SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(20 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header with Hero Animation
                _buildHeader(profile, scale),
                SizedBox(height: 16 * scale),

                // Profile Completion Indicator
                if (completion < 100) ...[
                  _buildCompletionCard(completion, completionMessage, scale),
                  SizedBox(height: 24 * scale),
                ],

                // Personal Information Section
                _buildSectionTitle('Personal Information', scale),
                _buildCard(
                  scale,
                  children: [
                    _buildInfoRow('Full Name', profile.fullName,
                        Icons.person_outline, scale),
                    if (profile.dateOfBirth != null)
                      _buildInfoRow(
                        'Date of Birth',
                        DateFormat('dd MMM yyyy').format(profile.dateOfBirth!),
                        Icons.calendar_today_outlined,
                        scale,
                        subtitle:
                            '${_calculateAge(profile.dateOfBirth!)} years old',
                      ),
                    if (profile.gender != null)
                      _buildInfoRow('Gender', profile.gender!, Icons.wc, scale),
                    if (profile.phoneNumber != null)
                      _buildInfoRow('Phone', profile.phoneNumber!,
                          Icons.phone_outlined, scale),
                    if (profile.address != null)
                      _buildInfoRow('Address', profile.address!,
                          Icons.location_on_outlined, scale),
                  ],
                ),
                SizedBox(height: 24 * scale),

                // Emergency & Medical Section
                _buildSectionTitle('Emergency & Medical', scale),
                _buildCard(
                  scale,
                  children: [
                    if (profile.emergencyContactName != null)
                      _buildInfoRow(
                        'Emergency Contact',
                        profile.emergencyContactName!,
                        Icons.contact_emergency_outlined,
                        scale,
                      ),
                    if (profile.emergencyContactPhone != null)
                      _buildInfoRow(
                        'Emergency Phone',
                        profile.emergencyContactPhone!,
                        Icons.phone_in_talk_outlined,
                        scale,
                      ),
                    if (profile.medicalNotes != null)
                      _buildInfoRow(
                        'Medical Notes',
                        profile.medicalNotes!,
                        Icons.medical_services_outlined,
                        scale,
                      ),
                    // Show warning if critical info is missing
                    if (!ProfileCompletionHelper.hasCriticalInfo(profile))
                      Container(
                        padding: EdgeInsets.all(12 * scale),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Colors.orange.shade700, size: 20),
                            SizedBox(width: 8 * scale),
                            Expanded(
                              child: Text(
                                'Please add emergency contact information',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 13 * scale,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 24 * scale),

                // Caregiver Linking Section (Only visible to Patient)
                if (!isCaregiver) ...[
                  _buildSectionTitle('Caregiver Access', scale),
                  _buildLinkingSection(scale),
                  SizedBox(height: 24 * scale),
                ],

                // Settings / Sign Out (Only visible to Patient)
                if (!isCaregiver) ...[
                  _buildSettingsSection(scale),
                ],

                SizedBox(height: 100 * scale),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(provider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(WidgetRef ref) async {
    // Delegate to the provider which handles picking and uploading
    await ref.read(profilePhotoUploadProvider.notifier).pickAndUpload();
  }

  Widget _buildHeader(PatientProfile profile, double scale) {
    final uploadState = ref.watch(profilePhotoUploadProvider);
    final isUploading = uploadState is AsyncLoading;

    // We fetch the profile image directly from the patients table as requested
    return FutureBuilder<Map<String, dynamic>?>(
        future: Supabase.instance.client
            .from('patients')
            .select('profile_photo_url')
            .eq('id', profile.id)
            .maybeSingle()
            .then((value) => value),
        builder: (context, snapshot) {
          String? profilePhotoUrl = profile.profileImageUrl;

          if (snapshot.hasData && snapshot.data != null) {
            final fetchedUrl = snapshot.data!['profile_photo_url'] as String?;
            if (fetchedUrl != null) {
              profilePhotoUrl = fetchedUrl;
            }
          }

          return Column(
            children: [
              // Hero animation for profile avatar
              // Editable Avatar
              EditableAvatar(
                profilePhotoUrl: profilePhotoUrl,
                isUploading: isUploading,
                radius: 70 * scale,
                onTap: () => _pickAndUploadImage(ref),
              ),
              SizedBox(height: 16 * scale),
              Text(
                profile.fullName,
                style: TextStyle(
                  fontSize: 26 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              if (profile.dateOfBirth != null)
                Text(
                  '${_calculateAge(profile.dateOfBirth!)} years old',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          );
        });
  }

  Widget _buildCompletionCard(int completion, String message, double scale) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 10,
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
              Text(
                'Profile Completion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$completion%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13 * scale,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(double scale, {required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.isEmpty
            ? [
                Padding(
                  padding: EdgeInsets.all(16 * scale),
                  child: Text(
                    'No information available',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14 * scale,
                    ),
                  ),
                ),
              ]
            : children,
      ),
    );
  }

  Widget _buildSectionTitle(String title, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * scale, left: 4 * scale),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20 * scale,
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade800,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    double scale, {
    String? subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10 * scale),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.teal.shade700, size: 20 * scale),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15 * scale,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2 * scale),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12 * scale,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkingSection(double scale) {
    final activeCode = ref.watch(activeInviteCodeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Invite Code Card
        _buildCard(scale, children: [
          activeCode.when(
            data: (code) {
              if (code != null) {
                return Column(
                  children: [
                    const Text(
                      'Share this code with your caregiver',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 12 * scale),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20 * scale, vertical: 12 * scale),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12 * scale),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            code.code,
                            style: TextStyle(
                              fontSize: 28 * scale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          SizedBox(width: 8 * scale),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.teal),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: code.code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code copied to clipboard!'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Text(
                      'Expires in ${code.expiresAt.difference(DateTime.now()).inHours} hours',
                      style: TextStyle(fontSize: 12 * scale, color: Colors.red),
                    ),
                  ],
                );
              } else {
                return Center(
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(linkControllerProvider.notifier)
                        .generateCode(),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Generate Invite Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.all(16 * scale),
                    ),
                  ),
                );
              }
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ]),

        SizedBox(height: 24 * scale),

        // 2. Linked Caregivers Section
        Text(
          'Linked Caregivers',
          style: TextStyle(
            fontSize: 20 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
        SizedBox(height: 12 * scale),

        _buildCard(scale, children: [
          FutureBuilder<List<dynamic>>(
            future: Supabase.instance.client
                .from('caregiver_patient_links')
                .select('''
                  *,
                  caregiver_profiles:caregiver_id (*)
                ''')
                .eq('patient_id',
                    Supabase.instance.client.auth.currentUser?.id ?? '')
                .order('linked_at', ascending: true),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: LinearProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                // Return detailed error if fetch fails for easy debugging
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error loading caregivers: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)),
                );
              }

              final links = snapshot.data ?? <dynamic>[];

              if (links.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(16.0 * scale),
                  child: const Center(
                    child: Text(
                      'No caregivers linked yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: links.map((link) {
                  final caregiverProfile =
                      link['caregiver_profiles'] as Map<String, dynamic>? ?? {};

                  final fullName = 'Linked Caregiver';
                  final photoUrl =
                      caregiverProfile['profile_photo_url'] as String?;
                  final relationship =
                      caregiverProfile['relationship'] as String?;
                  final phone =
                      caregiverProfile['phone'] as String? ?? 'No phone number';

                  return Container(
                    margin: EdgeInsets.only(bottom: 8 * scale),
                    padding: EdgeInsets.all(8 * scale),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12 * scale),
                      color: Colors.teal.shade50.withOpacity(0.5),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 24 * scale,
                        backgroundColor: Colors.teal.shade100,
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(
                                fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : 'C',
                                style: TextStyle(
                                  color: Colors.teal.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (relationship != null)
                            Text(relationship,
                                style: TextStyle(color: Colors.teal.shade700)),
                          Text(phone, style: TextStyle(fontSize: 13 * scale)),
                        ],
                      ),
                      trailing: const Icon(Icons.verified, color: Colors.teal),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16 * scale)),
                            contentPadding: EdgeInsets.all(24 * scale),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 40 * scale,
                                  backgroundColor: Colors.teal.shade100,
                                  backgroundImage: photoUrl != null
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl == null
                                      ? Text(
                                          fullName.isNotEmpty
                                              ? fullName[0].toUpperCase()
                                              : 'C',
                                          style: TextStyle(
                                              fontSize: 32 * scale,
                                              color: Colors.teal.shade800,
                                              fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                SizedBox(height: 16 * scale),
                                Text(
                                  fullName,
                                  style: TextStyle(
                                      fontSize: 20 * scale,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8 * scale),
                                if (relationship != null) ...[
                                  Text(
                                    relationship,
                                    style: TextStyle(
                                        fontSize: 16 * scale,
                                        color: Colors.teal.shade700),
                                  ),
                                  SizedBox(height: 8 * scale),
                                ],
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.phone,
                                        size: 16 * scale,
                                        color: Colors.grey.shade600),
                                    SizedBox(width: 8 * scale),
                                    Text(
                                      phone,
                                      style: TextStyle(
                                          fontSize: 16 * scale,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24 * scale),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8 * scale)),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12 * scale),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ]),
      ],
    );
  }

  Widget _buildSettingsSection(double scale) {
    return _buildCard(scale, children: [
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
        onTap: _signOut,
      ),
    ]);
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
