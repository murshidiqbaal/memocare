import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/profile_completion_helper.dart';
import '../../../data/models/patient_profile.dart';
import '../../../features/linking/presentation/controllers/link_controller.dart';
import '../../../providers/auth_provider.dart';
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
                if (completion < 100)
                  _buildCompletionCard(completion, completionMessage, scale),
                SizedBox(height: 24 * scale),

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

  Widget _buildHeader(PatientProfile profile, double scale) {
    return Column(
      children: [
        // Hero animation for profile avatar
        Hero(
          tag: 'profile_avatar_${profile.id}',
          child: Container(
            width: 140 * scale,
            height: 140 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.teal.shade50,
              border: Border.all(color: Colors.teal.shade200, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              image: profile.profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(profile.profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profile.profileImageUrl == null
                ? Icon(
                    Icons.person,
                    size: 70 * scale,
                    color: Colors.teal.shade400,
                  )
                : null,
          ),
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
    final linkedProfiles = ref.watch(linkedProfilesProvider);

    return _buildCard(scale, children: [
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
                onPressed: () =>
                    ref.read(linkControllerProvider.notifier).generateCode(),
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
      SizedBox(height: 24 * scale),
      const Divider(),
      SizedBox(height: 16 * scale),
      Text(
        'Linked Caregivers',
        style: TextStyle(
          fontSize: 16 * scale,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      SizedBox(height: 12 * scale),
      linkedProfiles.when(
        data: (links) {
          if (links.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'No caregivers linked yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          return Column(
            children: links.map((link) {
              final profile = link.relatedProfile;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Text(
                    (profile?.fullName ?? 'C')[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(profile?.fullName ?? 'Unknown Caregiver'),
                subtitle: const Text('Caregiver'),
                trailing: IconButton(
                  icon: const Icon(Icons.link_off, color: Colors.red),
                  onPressed: () => ref
                      .read(linkControllerProvider.notifier)
                      .removeLink(link.id),
                ),
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: LinearProgressIndicator()),
        error: (e, _) => Text('Error loading caregivers: $e'),
      ),
    ]);
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
        (today.month == birthDate.month && today.day < birthDate.day)) age--;
    return age;
  }
}
