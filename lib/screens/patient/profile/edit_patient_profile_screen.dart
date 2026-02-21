import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../data/models/patient_profile.dart';
import '../../../providers/auth_provider.dart';
import 'viewmodels/patient_profile_viewmodel.dart';

/// Dedicated Edit/Create Patient Profile Screen
/// Follows HIPAA-style security, elder-friendly UI, and production-ready patterns
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
    extends ConsumerState<EditPatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _medicalNotesController;

  // State
  DateTime? _selectedDob;
  String? _selectedGender;
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _medicalNotesController = TextEditingController();
  }

  void _loadExistingData() {
    if (widget.existingProfile != null) {
      final profile = widget.existingProfile!;
      _nameController.text = profile.fullName;
      _phoneController.text = profile.phoneNumber ?? '';
      _addressController.text = profile.address ?? '';
      _emergencyNameController.text = profile.emergencyContactName ?? '';
      _emergencyPhoneController.text = profile.emergencyContactPhone ?? '';
      _medicalNotesController.text = profile.medicalNotes ?? '';
      _selectedDob = profile.dateOfBirth;
      _selectedGender = profile.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _medicalNotesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      final userId = widget.patientId ?? user?.id;

      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Create updated profile
      final updatedProfile = PatientProfile(
        id: userId,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        dateOfBirth: _selectedDob,
        gender: _selectedGender,
        emergencyContactName: _emergencyNameController.text.trim().isEmpty
            ? null
            : _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        medicalNotes: _medicalNotesController.text.trim().isEmpty
            ? null
            : _medicalNotesController.text.trim(),
        profileImageUrl: widget.existingProfile?.profileImageUrl,
        createdAt: widget.existingProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      // Get the appropriate provider
      final provider = widget.patientId != null
          ? patientMonitoringProvider(widget.patientId!)
          : patientProfileProvider;

      // Update profile fields first
      await ref.read(provider.notifier).updateProfile(updatedProfile);

      // Upload image last so it appends the new photo url to the updated profile state
      if (_selectedImage != null) {
        await ref.read(provider.notifier).updateProfileImage(_selectedImage!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profile saved successfully!'),
            backgroundColor: Colors.teal,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final isNewProfile = widget.existingProfile == null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(isNewProfile ? 'Create Profile' : 'Edit Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(20 * scale),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Photo Section
                  _buildPhotoSection(scale),
                  SizedBox(height: 32 * scale),

                  // Personal Information
                  _buildSectionTitle('Personal Information', scale),
                  _buildCard(
                    scale,
                    children: [
                      _buildTextField(
                        'Full Name',
                        _nameController,
                        scale,
                        isRequired: true,
                        icon: Icons.person_outline,
                      ),
                      _buildDatePicker('Date of Birth', scale),
                      _buildGenderDropdown(scale),
                      _buildTextField(
                        'Phone Number',
                        _phoneController,
                        scale,
                        keyboardType: TextInputType.phone,
                        icon: Icons.phone_outlined,
                      ),
                      _buildTextField(
                        'Address',
                        _addressController,
                        scale,
                        maxLines: 2,
                        icon: Icons.location_on_outlined,
                      ),
                    ],
                  ),
                  SizedBox(height: 24 * scale),

                  // Emergency & Medical Information
                  _buildSectionTitle('Emergency & Medical', scale),
                  _buildCard(
                    scale,
                    children: [
                      _buildTextField(
                        'Emergency Contact Name',
                        _emergencyNameController,
                        scale,
                        icon: Icons.contact_emergency_outlined,
                      ),
                      _buildTextField(
                        'Emergency Contact Phone',
                        _emergencyPhoneController,
                        scale,
                        keyboardType: TextInputType.phone,
                        icon: Icons.phone_in_talk_outlined,
                      ),
                      _buildTextField(
                        'Medical Notes',
                        _medicalNotesController,
                        scale,
                        maxLines: 4,
                        icon: Icons.medical_services_outlined,
                        hint: 'Allergies, medications, conditions...',
                      ),
                    ],
                  ),
                  SizedBox(height: 40 * scale),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 18 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 20 * scale,
                            width: 20 * scale,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isNewProfile ? 'CREATE PROFILE' : 'SAVE CHANGES',
                            style: TextStyle(
                              fontSize: 18 * scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  SizedBox(height: 100 * scale),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isSaving)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Saving profile...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(double scale) {
    final userId = widget.patientId ?? ref.read(currentUserProvider)?.id;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Hero(
            tag: 'profile_avatar_$userId',
            child: Container(
              width: 140 * scale,
              height: 140 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.shade50,
                border: Border.all(color: Colors.teal.shade200, width: 4),
                image: _selectedImage != null
                    ? DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      )
                    : widget.existingProfile?.profileImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(
                                widget.existingProfile!.profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: _selectedImage == null &&
                      widget.existingProfile?.profileImageUrl == null
                  ? Icon(
                      Icons.person,
                      size: 70 * scale,
                      color: Colors.teal.shade400,
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton.small(
              onPressed: _pickImage,
              backgroundColor: Colors.teal,
              child: const Icon(Icons.camera_alt, color: Colors.white),
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
      child: Column(children: children),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    double scale, {
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? icon,
    String? hint,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16 * scale),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(fontSize: 16 * scale),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: Colors.teal.shade700,
            fontSize: 14 * scale,
          ),
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14 * scale,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12 * scale),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12 * scale),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12 * scale),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          prefixIcon: icon != null ? Icon(icon, color: Colors.teal) : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: 16 * scale,
          ),
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field is required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDatePicker(String label, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16 * scale),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDob ?? DateTime(1960),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Colors.teal,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (date != null) {
            setState(() => _selectedDob = date);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: Colors.teal.shade700,
              fontSize: 14 * scale,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: const BorderSide(color: Colors.teal, width: 2),
            ),
            prefixIcon:
                const Icon(Icons.calendar_today_outlined, color: Colors.teal),
            filled: true,
            fillColor: Colors.white,
          ),
          child: Text(
            _selectedDob == null
                ? 'Select Date'
                : DateFormat('dd MMM yyyy').format(_selectedDob!),
            style: TextStyle(
              color: _selectedDob == null ? Colors.grey : Colors.black87,
              fontSize: 16 * scale,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16 * scale),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedGender,
        decoration: InputDecoration(
          labelText: 'Gender',
          labelStyle: TextStyle(
            color: Colors.teal.shade700,
            fontSize: 14 * scale,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12 * scale),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12 * scale),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          prefixIcon: const Icon(Icons.wc, color: Colors.teal),
          filled: true,
          fillColor: Colors.white,
        ),
        items: ['Male', 'Female', 'Other']
            .map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender, style: TextStyle(fontSize: 16 * scale)),
                ))
            .toList(),
        onChanged: (value) => setState(() => _selectedGender = value),
      ),
    );
  }
}
