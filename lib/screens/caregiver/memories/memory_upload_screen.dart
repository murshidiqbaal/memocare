import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/memory.dart';
import '../../../providers/memory_providers.dart';

class MemoryUploadScreen extends ConsumerStatefulWidget {
  final String patientId;
  final Memory? existingMemory;

  const MemoryUploadScreen({
    super.key,
    required this.patientId,
    this.existingMemory,
  });

  @override
  ConsumerState<MemoryUploadScreen> createState() => _MemoryUploadScreenState();
}

class _MemoryUploadScreenState extends ConsumerState<MemoryUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  String? _localPhotoPath;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingMemory != null) {
      _titleController.text = widget.existingMemory!.title;
      _descriptionController.text = widget.existingMemory!.description ?? '';
      _selectedDate = widget.existingMemory!.eventDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _localPhotoPath = pickedFile.path;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveMemory() async {
    if (!_formKey.currentState!.validate()) return;

    // Safety check BEFORE database payload generation
    if (widget.patientId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Cannot save memory: No patient selected. Please select a patient from the dashboard.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final memory = Memory(
      id: widget.existingMemory?.id ?? const Uuid().v4(),
      patientId: widget.patientId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      eventDate: _selectedDate,
      localPhotoPath: _localPhotoPath,
      imageUrl: widget.existingMemory?.imageUrl,
      createdAt: widget.existingMemory?.createdAt ?? DateTime.now(),
    );

    if (widget.existingMemory == null) {
      await ref.read(memoryUploadProvider.notifier).uploadMemory(memory);
    } else {
      await ref.read(memoryUploadProvider.notifier).updateMemory(memory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(memoryUploadProvider);

    ref.listen<MemoryUploadState>(memoryUploadProvider, (previous, next) {
      if (next.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Memory saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            Text(widget.existingMemory == null ? 'Add Memory' : 'Edit Memory'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: uploadState.isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _localPhotoPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(_localPhotoPath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.existingMemory?.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      widget.existingMemory!.imageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate,
                                          size: 64,
                                          color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to add photo',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Memory Title *',
                        hintText: 'e.g., Family Picnic',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add details about this memory...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: Colors.grey.shade700),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate == null
                                  ? 'Select event date (Optional)'
                                  : DateFormat('MMM dd, yyyy')
                                      .format(_selectedDate!),
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDate == null
                                    ? Colors.grey.shade600
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveMemory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.existingMemory == null
                            ? 'Add Memory'
                            : 'Update Memory',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
