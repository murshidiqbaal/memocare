import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/memory.dart';
import '../../../features/patient_selection/presentation/widgets/patient_bottom_sheet_picker.dart';
import '../../../features/patient_selection/providers/patient_selection_provider.dart';
import '../../../widgets/patient_selector_dropdown.dart';
import 'memory_upload_screen.dart';
import 'memory_viewmodel.dart';

class CaregiverMemoriesScreen extends ConsumerWidget {
  const CaregiverMemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientState = ref.watch(patientSelectionProvider);
    final patientId = patientState.selectedPatient?.id ?? '';

    // No patient selected
    if (patientId.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const PatientSelectorDropdown(),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'No patient selected',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Text(
                'Use the dropdown above or long-press\na navigation tab to select a patient.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => PatientBottomSheetPicker.show(context, ref),
                icon: const Icon(Icons.person_search),
                label: const Text('Select Patient'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ],
          ),
        ),
      );
    }

    final state = ref.watch(memoryViewModelProvider(patientId));
    final viewModel = ref.read(memoryViewModelProvider(patientId).notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const PatientSelectorDropdown(),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              viewModel.refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing memories...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (state.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(
                          color: Colors.orange.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: state.isLoading && state.memories.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.memories.isEmpty
                    ? _buildEmptyState(context)
                    : RefreshIndicator(
                        onRefresh: () => viewModel.refresh(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: state.memories.length,
                          itemBuilder: (context, index) {
                            final memory = state.memories[index];
                            return _buildMemoryCard(
                                context, ref, memory, viewModel, patientId);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToUpload(context, ref, null, patientId),
        label: const Text('Add Memory'),
        icon: const Icon(Icons.add_photo_alternate),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No memories yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos and stories to help\nyour loved one remember.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(
    BuildContext context,
    WidgetRef ref,
    Memory memory,
    MemoryViewModel viewModel,
    String patientId,
  ) {
    return GestureDetector(
      onTap: () => _navigateToUpload(context, ref, memory, patientId),
      onLongPress: () => _showDeleteDialog(context, memory, viewModel),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: memory.imageUrl != null && memory.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: memory.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image,
                                color: Colors.grey.shade400, size: 36),
                            const SizedBox(height: 4),
                            Text('Image failed',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 10)),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.teal.shade50,
                      child: Icon(Icons.photo,
                          size: 48, color: Colors.teal.shade200),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memory.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (memory.eventDate != null)
                          Text(
                            DateFormat('MMM dd, yyyy')
                                .format(memory.eventDate!),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        _showDeleteDialog(context, memory, viewModel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToUpload(
    BuildContext context,
    WidgetRef ref,
    Memory? memory,
    String patientId,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoryUploadScreen(
          patientId: patientId,
          existingMemory: memory,
        ),
      ),
    );

    if (result == true && context.mounted) {
      ref.read(memoryViewModelProvider(patientId).notifier).refresh();
    }
  }

  void _showDeleteDialog(
      BuildContext context, Memory memory, MemoryViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memory?'),
        content: Text('Are you sure you want to delete "${memory.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context); // Close dialog immediately

              await viewModel.deleteMemory(memory);

              if (context.mounted) {
                // Not strictly needed since we captured scaffoldMessenger but good practice
              }

              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Memory deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
