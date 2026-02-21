import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/patient_selection_provider.dart';

class PatientBottomSheetPicker {
  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _BottomSheetContent();
      },
    );
  }
}

class _BottomSheetContent extends ConsumerWidget {
  const _BottomSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientState = ref.watch(patientSelectionProvider);
    final theme = Theme.of(context);

    // Animation container for smooth entry
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26, blurRadius: 10, spreadRadius: 0)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Active Patient',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close picker',
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Content Switcher
                if (patientState.isLoading &&
                    patientState.linkedPatients.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (patientState.errorMessage != null &&
                    patientState.linkedPatients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading patients',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => ref
                              .read(patientSelectionProvider.notifier)
                              .fetchLinkedPatients(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        )
                      ],
                    ),
                  )
                else if (patientState.linkedPatients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.person_search,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No linked patients found.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connect with a patient first to start managing their care.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                      ),
                      itemCount: patientState.linkedPatients.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final patient = patientState.linkedPatients[index];
                        final isSelected =
                            patientState.selectedPatient?.id == patient.id;

                        return Semantics(
                          label: 'Select patient ${patient.fullName}',
                          selected: isSelected,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            selected: isSelected,
                            selectedTileColor: theme
                                .colorScheme.primaryContainer
                                .withOpacity(0.3),
                            onTap: () {
                              ref
                                  .read(patientSelectionProvider.notifier)
                                  .setSelectedPatient(patient);
                              Navigator.pop(context);
                              // Optional: Show snackbar confirmation
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Switched to ${patient.fullName}'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              backgroundImage:
                                  patient.profileImageUrl != null &&
                                          patient.profileImageUrl!.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          patient.profileImageUrl!)
                                      : null,
                              child: patient.profileImageUrl == null ||
                                      patient.profileImageUrl!.isEmpty
                                  ? Text(
                                      patient.fullName.isNotEmpty
                                          ? patient.fullName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: theme
                                            .colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              patient.fullName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle,
                                    color: theme.colorScheme.primary)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
