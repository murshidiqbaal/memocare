import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/caregiver.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/caregiver_profile_provider.dart';

class EditCaregiverProfileScreen extends ConsumerStatefulWidget {
  final Caregiver? existingProfile;
  const EditCaregiverProfileScreen({super.key, this.existingProfile});

  @override
  ConsumerState<EditCaregiverProfileScreen> createState() =>
      _EditCaregiverProfileScreenState();
}

class _EditCaregiverProfileScreenState
    extends ConsumerState<EditCaregiverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;

  // Relationship Options
  final List<String> _relationshipOptions = [
    'Son',
    'Daughter',
    'Spouse',
    'Grandchild',
    'Professional Caregiver',
    'Other'
  ];
  String? _selectedRelationship;

  bool _notificationEnabled = true;
  String? _profilePhotoUrl;
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _phoneController =
        TextEditingController(text: widget.existingProfile?.phone ?? '');

    // Set initial relationship or default to first option/null
    _selectedRelationship = widget.existingProfile?.relationship;
    if (_selectedRelationship != null &&
        !_relationshipOptions.contains(_selectedRelationship)) {
      // If existing relationship is not in options, add it or default to Other?
      // For simplicity, just add it temporarily or map to Other.
      // Better: Just let it be separate if needed, but for dropdown consistency:
      if (!_relationshipOptions.contains(_selectedRelationship)) {
        _relationshipOptions.add(_selectedRelationship!);
      }
    }

    _notificationEnabled = widget.existingProfile?.notificationEnabled ?? true;
    _profilePhotoUrl = widget.existingProfile?.profilePhotoUrl;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('No user found');

      String? photoUrl = _profilePhotoUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        photoUrl = await ref
            .read(caregiverProfileProvider.notifier)
            .uploadPhoto(_selectedImage!);
      }

      final caregiver = Caregiver(
        id: widget.existingProfile?.id ?? '', // Upsert ignores ID for new
        userId: user.id,
        phone: _phoneController.text.trim(),
        relationship: _selectedRelationship,
        notificationEnabled: _notificationEnabled,
        profilePhotoUrl: photoUrl,
        createdAt: widget.existingProfile?.createdAt ?? DateTime.now(),
      );

      await ref
          .read(caregiverProfileProvider.notifier)
          .upsertProfile(caregiver);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile saved successfully!'),
              backgroundColor: Colors.teal),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            widget.existingProfile == null ? 'Create Profile' : 'Edit Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24 * scale),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'caregiver_avatar',
                        child: CircleAvatar(
                          radius: 60 * scale,
                          backgroundColor: Colors.teal.shade50,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_profilePhotoUrl != null
                                  ? NetworkImage(_profilePhotoUrl!)
                                  : null) as ImageProvider?,
                          child:
                              _selectedImage == null && _profilePhotoUrl == null
                                  ? Icon(Icons.add_a_photo,
                                      size: 40 * scale, color: Colors.teal)
                                  : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: Colors.teal, shape: BoxShape.circle),
                          child: const Icon(Icons.edit,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40 * scale),

              // Fields
              _buildTextField('Phone Number', _phoneController, Icons.phone,
                  TextInputType.phone, scale),
              SizedBox(height: 20 * scale),
              // Relationship Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedRelationship,
                decoration: InputDecoration(
                  labelText: 'Relationship to Patient',
                  prefixIcon:
                      Icon(Icons.family_restroom, color: Colors.teal.shade300),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: Colors.teal, width: 2)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _relationshipOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedRelationship = newValue;
                  });
                },
                validator: (val) => val == null || val.isEmpty
                    ? 'Please select a relationship'
                    : null,
              ),
              SizedBox(height: 32 * scale),

              // Notification Toggle
              Container(
                padding: EdgeInsets.all(16 * scale),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active,
                        color: Colors.teal.shade700),
                    SizedBox(width: 16 * scale),
                    const Expanded(
                      child: Text(
                        'Enable Notifications',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Switch(
                      value: _notificationEnabled,
                      onChanged: (val) =>
                          setState(() => _notificationEnabled = val),
                      activeThumbColor: Colors.teal,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48 * scale),

              // Save and Cancel Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 18 * scale),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: Colors.teal),
                      ),
                      child: const Text('CANCEL',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.teal)),
                    ),
                  ),
                  SizedBox(width: 16 * scale),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 18 * scale),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('SAVE',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      IconData icon, TextInputType type, double scale) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal.shade300),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.teal, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (val) =>
          val == null || val.isEmpty ? 'This field is required' : null,
    );
  }
}
