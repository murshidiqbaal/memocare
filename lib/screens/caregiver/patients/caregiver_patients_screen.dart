import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/patient.dart';
import '../../../providers/caregiver_patients_provider.dart';
import '../../patient/profile/patient_profile_screen.dart';
import 'add_patient_screen.dart';

class CaregiverPatientsScreen extends ConsumerWidget {
  const CaregiverPatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(connectedPatientsStreamProvider);
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPatientScreen()),
          );
        },
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Patient',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: patientsAsync.when(
        data: (patients) {
          if (patients.isEmpty) {
            return _buildEmptyState(context, scale);
          }
          return ListView.builder(
            padding: EdgeInsets.all(20 * scale),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return _buildPatientCard(context, ref, patient, scale);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double scale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 100 * scale, color: Colors.grey.shade300),
          SizedBox(height: 24 * scale),
          Text(
            'No patients connected yet',
            style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600),
          ),
          SizedBox(height: 12 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40 * scale),
            child: Text(
              'To start monitoring, add a patient using their unique invite code.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14 * scale, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(
      BuildContext context, WidgetRef ref, Patient patient, double scale) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16 * scale),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          // Navigate to patient profile
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientProfileScreen(patientId: patient.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Row(
            children: [
              // Patient Photo
              Hero(
                tag: 'patient_avatar_${patient.id}',
                child: CircleAvatar(
                  radius: 30 * scale,
                  backgroundColor: Colors.teal.shade50,
                  backgroundImage: patient.profilePhotoUrl != null
                      ? NetworkImage(patient.profilePhotoUrl!)
                      : null,
                  child: patient.profilePhotoUrl == null
                      ? Icon(Icons.person, color: Colors.teal.shade300)
                      : null,
                ),
              ),
              SizedBox(width: 16 * scale),

              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName ?? 'Unnamed Patient',
                      style: TextStyle(
                          fontSize: 18 * scale, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4 * scale),
                    if (patient.phone != null)
                      Text(
                        patient.phone!,
                        style: TextStyle(
                            fontSize: 14 * scale, color: Colors.grey.shade600),
                      ),
                    SizedBox(height: 4 * scale),
                    Text(
                      'Linked since: ${patient.linkedAt != null ? patient.linkedAt!.toLocal().toString().split(' ')[0] : 'Unknown'}',
                      style: TextStyle(
                          fontSize: 12 * scale, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: const Icon(Icons.link_off, color: Colors.redAccent),
                onPressed: () => _confirmRemove(context, ref, patient),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Connection'),
        content: Text(
            'Are you sure you want to stop monitoring ${patient.fullName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(caregiverConnectionControllerProvider.notifier)
          .removeConnection(patient.id);
    }
  }
}
