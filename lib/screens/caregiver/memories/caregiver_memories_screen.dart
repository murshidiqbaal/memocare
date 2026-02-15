import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/memory.dart';
import 'memory_upload_screen.dart';
import 'memory_viewmodel.dart';

class CaregiverMemoriesScreen extends ConsumerWidget {
  final String patientId;

  const CaregiverMemoriesScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoryViewModelProvider(patientId));
    final viewModel = ref.read(memoryViewModelProvider(patientId).notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Memories'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              viewModel.refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing memories...')),
              );
            },
          ),
        ],
      ),
      body: state.isLoading && state.memories.isEmpty
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
                      return _buildMemoryCard(context, memory, viewModel);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToUpload(context, null, patientId),
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
      BuildContext context, Memory memory, MemoryViewModel viewModel) {
    return GestureDetector(
      onTap: () => _navigateToUpload(context, memory, patientId),
      onLongPress: () => _showDeleteDialog(context, memory, viewModel),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: memory.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: memory.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child:
                          const Icon(Icons.photo, size: 48, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memory.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (memory.eventDate != null)
                    Text(
                      DateFormat('MMM dd, yyyy').format(memory.eventDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (!memory.isSynced)
                    Row(
                      children: [
                        Icon(Icons.cloud_off, size: 12, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          'Not synced',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
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
      BuildContext context, Memory? memory, String selectedPatientId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoryUploadScreen(
          patientId: selectedPatientId,
          existingMemory: memory,
        ),
      ),
    );

    if (result == true && context.mounted) {
      // Refresh handled by ViewModel
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
            onPressed: () {
              viewModel.deleteMemory(memory.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memory deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
