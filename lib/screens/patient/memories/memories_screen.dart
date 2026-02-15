import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/memory_providers.dart';

class MemoriesScreen extends ConsumerWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final patientId = user?.id;

    if (patientId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('My Memories'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: Text('Please log in to view memories')),
      );
    }

    final memoryState = ref.watch(memoryListProvider(patientId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Memories'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(memoryListProvider(patientId).notifier).refresh();
            },
          ),
        ],
      ),
      body: memoryState.isLoading && memoryState.memories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : memoryState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading memories',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          memoryState.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(memoryListProvider(patientId).notifier)
                              .refresh();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : memoryState.memories.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(memoryListProvider(patientId).notifier)
                          .refresh(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: memoryState.memories.length,
                        itemBuilder: (context, index) {
                          final memory = memoryState.memories[index];
                          return _buildMemoryCard(context, memory);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            'No Memories Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Your caregiver will add photos\nand stories for you to remember.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(BuildContext context, memory) {
    return GestureDetector(
      onTap: () => _showMemoryDetail(context, memory),
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
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey, size: 48),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child:
                          const Icon(Icons.photo, size: 64, color: Colors.grey),
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
                      fontSize: 18,
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
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemoryDetail(BuildContext context, memory) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (memory.imageUrl != null)
                Expanded(
                  flex: 3,
                  child: CachedNetworkImage(
                    imageUrl: memory.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image_not_supported, size: 64),
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memory.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (memory.eventDate != null)
                        Text(
                          DateFormat('MMMM dd, yyyy').format(memory.eventDate!),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      if (memory.description != null) ...[
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              memory.description!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Close',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
