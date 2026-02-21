import 'package:flutter/material.dart';

import '../../../../../data/models/caregiver_patient_link.dart';

/// Patient Selector Dropdown
/// Allows caregiver to switch between linked patients
class PatientSelector extends StatelessWidget {
  final List<CaregiverPatientLink> patients;
  final CaregiverPatientLink? selectedPatient;
  final Function(CaregiverPatientLink) onPatientSelected;

  const PatientSelector({
    super.key,
    required this.patients,
    required this.selectedPatient,
    required this.onPatientSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No patients linked to your account',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPatient?.id,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.teal.shade700,
            size: 32,
          ),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          items: patients.map((patient) {
            return DropdownMenuItem<String>(
              value: patient.id,
              child: Row(
                children: [
                  // Patient photo
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: patient.patientPhotoUrl != null
                        ? NetworkImage(patient.patientPhotoUrl!)
                        : null,
                    child: patient.patientPhotoUrl == null
                        ? Text(
                            (patient.patientName != null &&
                                    patient.patientName!.isNotEmpty)
                                ? patient.patientName![0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Patient name and relationship
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          patient.patientName ?? 'Unknown Patient',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (patient.relationship != null)
                          Text(
                            patient.relationship!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Primary indicator
                  if (patient.isPrimary)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Primary',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? value) {
            if (value != null) {
              final patient = patients.firstWhere((p) => p.id == value);
              onPatientSelected(patient);
            }
          },
        ),
      ),
    );
  }
}
