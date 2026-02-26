import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/patient_model.dart';
import '../../providers/patient_selection_provider.dart';

class PatientAppBarDropdown extends ConsumerWidget {
  const PatientAppBarDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientState = ref.watch(patientSelectionProvider);
    final theme = Theme.of(context);

    if (patientState.isLoading && patientState.linkedPatients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Wrap in a Material for styling and accessibility
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Patient>(
          value:
              patientState.linkedPatients.contains(patientState.selectedPatient)
                  ? patientState.selectedPatient
                  : null,
          hint: Text(
            patientState.linkedPatients.isEmpty
                ? 'No Patients'
                : 'Select Patient',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          onChanged: (Patient? newValue) {
            if (newValue != null) {
              ref
                  .read(patientSelectionProvider.notifier)
                  .setSelectedPatient(newValue);
            }
          },
          items: patientState.linkedPatients
              .map<DropdownMenuItem<Patient>>((Patient patient) {
            return DropdownMenuItem<Patient>(
              value: patient,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: patientState.selectedPatient?.id == patient.id
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    patient.fullName.length > 15
                        ? '${patient.fullName.substring(0, 15)}...'
                        : patient.fullName,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
