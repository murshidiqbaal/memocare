import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/user/caregiver_profile.dart';
import 'viewmodels/caregiver_profile_viewmodel.dart';

class EditCaregiverProfileScreen extends ConsumerStatefulWidget {
  final CaregiverProfile? initialProfile;

  const EditCaregiverProfileScreen({super.key, this.initialProfile});

  @override
  ConsumerState<EditCaregiverProfileScreen> createState() =>
      _EditCaregiverProfileScreenState();
}

class _EditCaregiverProfileScreenState
    extends ConsumerState<EditCaregiverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _relationship = 'Son'; // Default
  bool _notificationsEnabled = true;
  File? _selectedImage;
  bool _isLoading = false;

  final List<String> _relationships = [
    'Son',
    'Daughter',
    'Spouse',
    'Nurse',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialProfile?.fullName ?? '');
    _phoneController =
        TextEditingController(text: widget.initialProfile?.phoneNumber ?? '');
    _relationship = widget.initialProfile?.relationship ?? 'Son';
    _notificationsEnabled = widget.initialProfile?.notificationsEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(caregiverProfileViewModelProvider.notifier).saveProfile(
            fullName: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            relationship: _relationship,
            notificationsEnabled: _notificationsEnabled,
            newPhoto: _selectedImage,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context); // Go back to view screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.initialProfile == null ? 'Create Profile' : 'Edit Profile'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 1. Profile Photo
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.teal.shade50,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (widget.initialProfile?.photoUrl != null
                                    ? NetworkImage(
                                        widget.initialProfile!.photoUrl!)
                                    : null) as ImageProvider?,
                            child: (_selectedImage == null &&
                                    widget.initialProfile?.photoUrl == null)
                                ? const Icon(Icons.person,
                                    size: 60, color: Colors.teal)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.teal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 20, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('Change Photo'),
                    ),
                    const SizedBox(height: 24),

                    // 2. Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 3. Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter phone number'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 4. Relationship
                    DropdownButtonFormField<String>(
                      value: _relationships.contains(_relationship)
                          ? _relationship
                          : _relationships.first,
                      items: _relationships.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _relationship = newValue!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Relationship to Patient',
                        prefixIcon: const Icon(Icons.favorite_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Notifications
                    SwitchListTile(
                      title: const Text('Enable Notifications'),
                      subtitle:
                          const Text('Receive alerts about patient activity'),
                      value: _notificationsEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                      secondary:
                          const Icon(Icons.notifications_active_outlined),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    const SizedBox(height: 32),

                    // 6. Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text(widget.initialProfile == null
                            ? 'Create Profile'
                            : 'Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
