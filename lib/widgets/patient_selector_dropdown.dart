import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/active_patient_provider.dart';

/// A unified patient selector dropdown that reads from the global
/// [activePatientIdProvider]. It can be placed in any AppBar.
class PatientSelectorDropdown extends ConsumerWidget {
  const PatientSelectorDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedPatientsAsync = ref.watch(linkedPatientsProvider);
    final activePatientId = ref.watch(activePatientIdProvider);

    if (linkedPatientsAsync.isLoading) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Loading...',
              style: TextStyle(color: Colors.black, fontSize: 16)),
        ],
      );
    }

    if (linkedPatientsAsync.hasError ||
        linkedPatientsAsync.value == null ||
        linkedPatientsAsync.value!.isEmpty) {
      return const Text(
        'No Patients Linked',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      );
    }

    final patients = linkedPatientsAsync.value!;
    final selectedPatient = patients.any((p) => p.id == activePatientId)
        ? patients.firstWhere((p) => p.id == activePatientId)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPatient?.id,
          hint: const Text(
            'Select Patient',
            style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
          dropdownColor: Colors.white,
          style: const TextStyle(
            color: Colors.teal,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          isDense: true,
          items: patients.map((patient) {
            return DropdownMenuItem<String>(
              value: patient.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.teal.shade100,
                    backgroundImage: (patient.profileImageUrl != null &&
                            patient.profileImageUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(patient.profileImageUrl!)
                        : null,
                    child: (patient.profileImageUrl == null ||
                            patient.profileImageUrl!.isEmpty)
                        ? Text(
                            patient.fullName?.isNotEmpty == true
                                ? patient.fullName![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(patient.fullName ?? 'Linked Patient'),
                ],
              ),
            );
          }).toList(),
          onChanged: (patientId) {
            if (patientId != null) {
              ref
                  .read(activePatientIdProvider.notifier)
                  .setActivePatient(patientId);
            }
          },
        ),
      ),
    );
  }
}
