import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/models/person.dart';
import '../../../../screens/patient/reminders/widgets/voice_recorder_widget.dart';

class PeopleCardEditForm extends StatefulWidget {
  final Person? existingPerson;
  final String patientId;
  final Function(Person) onSave;

  const PeopleCardEditForm(
      {super.key,
      this.existingPerson,
      required this.patientId,
      required this.onSave});

  @override
  State<PeopleCardEditForm> createState() => _PeopleCardEditFormState();
}

class _PeopleCardEditFormState extends State<PeopleCardEditForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _relController;
  late TextEditingController _descController;
  File? _imageFile;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPerson;
    _nameController = TextEditingController(text: p?.name);
    _relController = TextEditingController(text: p?.relationship);
    _descController = TextEditingController(text: p?.description);
    _audioPath = p?.localAudioPath;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newPerson = Person(
        id: widget.existingPerson?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: widget.patientId,
        name: _nameController.text,
        relationship: _relController.text,
        description: _descController.text,
        photoUrl: widget.existingPerson?.photoUrl,
        voiceAudioUrl: widget.existingPerson?.voiceAudioUrl,
        localPhotoPath:
            _imageFile?.path ?? widget.existingPerson?.localPhotoPath,
        localAudioPath: _audioPath ?? widget.existingPerson?.localAudioPath,
        createdAt: widget.existingPerson?.createdAt ?? DateTime.now(),
      );
      widget.onSave(newPerson);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.existingPerson == null ? 'Add Person' : 'Edit Person'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Upload
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : (widget.existingPerson?.photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(
                                    widget.existingPerson!.photoUrl!),
                                fit: BoxFit.cover)
                            : null),
                  ),
                  child: _imageFile == null &&
                          widget.existingPerson?.photoUrl == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 40, color: Colors.grey),
                              Text('Tap to add photo'),
                            ],
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _relController,
                decoration: const InputDecoration(
                    labelText: 'Relationship (e.g. Son)',
                    border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              VoiceRecorderWidget(
                onRecordingComplete: (path) =>
                    setState(() => _audioPath = path),
                onDelete: () => setState(() => _audioPath = null),
                existingAudioPath: _audioPath,
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Person Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
