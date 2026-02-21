import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/caregiver_patients_provider.dart';
import '../../patient/profile/patient_profile_screen.dart';

class AddPatientScreen extends ConsumerStatefulWidget {
  const AddPatientScreen({super.key});

  @override
  ConsumerState<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends ConsumerState<AddPatientScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(caregiverConnectionControllerProvider);
    final patientsAsync = ref.watch(connectedPatientsStreamProvider);

    ref.listen(caregiverConnectionControllerProvider, (previous, next) {
      if (next.hasError) {
        showDialog(
            context: context,
            builder: (c) => AlertDialog(
                  title: const Text('Error'),
                  content:
                      Text(next.error.toString().replaceAll('Exception: ', '')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('OK'))
                  ],
                ));
      } else if (!next.isLoading && previous?.isLoading == true) {
        // Success
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Action successful!')));
        _codeController.clear();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Add Patient')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Enter Invite Code',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ask the patient to generate a code from their settings.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          hintText: '6-digit Code',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.key),
                        ),
                        style: const TextStyle(letterSpacing: 2),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) =>
                            v == null || v.length < 6 ? 'Invalid code' : null,
                      ),
                      const SizedBox(height: 16),
                      connectionState.isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    ref
                                        .read(
                                            caregiverConnectionControllerProvider
                                                .notifier)
                                        .connectUsingInviteCode(_codeController
                                            .text
                                            .toUpperCase()
                                            .trim());
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Link Patient'),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Your Patients',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            patientsAsync.when(
                data: (patients) {
                  if (patients.isEmpty) {
                    return const Center(child: Text('No patients linked yet.'));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: patient.profilePhotoUrl != null
                              ? NetworkImage(patient.profilePhotoUrl!)
                              : null,
                          child: patient.profilePhotoUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(patient.fullName ?? 'Unknown'),
                        subtitle: Text(
                            'Linked since ${patient.linkedAt != null ? DateFormat.yMMMd().format(patient.linkedAt!) : "Unknown"}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.link_off, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Remove Connection'),
                                content: Text('Remove ${patient.fullName}?'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(c),
                                      child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(c);
                                      ref
                                          .read(
                                              caregiverConnectionControllerProvider
                                                  .notifier)
                                          .removeConnection(patient.id);
                                    },
                                    child: const Text('Remove',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          // Navigate to patient profile
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PatientProfileScreen(patientId: patient.id),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                error: (e, s) => Text('Error loading patients: $e'),
                loading: () => const Center(child: CircularProgressIndicator()))
          ],
        ),
      ),
    );
  }
}
