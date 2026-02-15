import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/caregiver_patient_link.dart';
import '../../../providers/connection_providers.dart';
import '../../patient/profile/patient_profile_screen.dart';

class CaregiverConnectionsScreen extends ConsumerWidget {
  const CaregiverConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedPatients = ref.watch(linkedPatientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context, ref),
        label: const Text('Add Patient'),
        icon: const Icon(Icons.person_add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connected Patients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            linkedPatients.when(
              data: (patients) => patients.isEmpty
                  ? const _EmptyState(
                      icon: Icons.people_outline,
                      message:
                          'You haven\'t linked any patients yet.\nTap the button below to send an invite.',
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: patients.length,
                      itemBuilder: (context, index) =>
                          _PatientCard(patient: patients[index]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final repository = ref.read(connectionRepositoryProvider);

    // State for loading/error handled locally for simplicity in dialog
    // Ideally use a StateProvider or Controller
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Connect to Patient'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter the invite code shared by the patient.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Invite Code',
                    hintText: 'e.g. 123-abc',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a code';
                    }
                    return null;
                  },
                ),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          actions: [
            if (!isLoading)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            if (!isLoading)
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    setState(() => isLoading = true);
                    try {
                      await repository
                          .connectToPatient(codeController.text.trim());

                      // Refresh the list
                      ref.invalidate(linkedPatientsProvider);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Successfully connected to patient!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() => isLoading = false);
                      // Extract error message
                      final message =
                          e.toString().replaceFirst('Exception: ', '');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                },
                child: const Text('Connect'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final CaregiverPatientLink patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: const Icon(Icons.person, color: Colors.teal),
        ),
        title: Text(
          patient.patientName ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(patient.patientEmail ?? ''),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PatientProfileScreen(patientId: patient.patientId),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
