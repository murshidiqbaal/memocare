import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/memory_providers.dart';

/// Memory Highlight Card - Emotional design for memory recall
///
/// Shows the most recent memory photo uploaded to the `memory-photos`
/// Supabase bucket, with real title text from the database.
///
/// Healthcare-grade improvements:
/// - Fetches live photo from Supabase storage bucket
/// - Large rounded photo preview with real image
/// - Warm gradient overlay
/// - Elevated shadow for warmth
/// - Supportive emotional text
/// - Graceful placeholder when no memories exist
class MemoryHighlightCard extends ConsumerWidget {
  final VoidCallback onViewDay;

  const MemoryHighlightCard({
    super.key,
    required this.onViewDay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    // Get current patient's ID (patient is the logged-in user)
    final user = ref.watch(currentUserProvider);
    final patientId = user?.id ?? '';

    // Watch the live memory list from Supabase
    final memoryState =
        patientId.isNotEmpty ? ref.watch(memoryListProvider(patientId)) : null;

    // Pick the most recent memory that has a photo
    final latestMemory = memoryState?.memories
        .where((m) => m.imageUrl != null && m.imageUrl!.isNotEmpty)
        .firstOrNull;

    // Or just the latest memory even without a photo (for the title)
    final latestAny = memoryState?.memories.isNotEmpty == true
        ? memoryState!.memories.first
        : null;

    final displayMemory = latestMemory ?? latestAny;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.15),
            blurRadius: 20 * scale,
            offset: Offset(0, 8 * scale),
          ),
          BoxShadow(
            color: Colors.pink.withOpacity(0.08),
            blurRadius: 30 * scale,
            offset: Offset(0, 12 * scale),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Large rounded photo preview
          ClipRRect(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(12 * scale)),
            child: SizedBox(
              height: 220 * scale,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Photo from Supabase storage or placeholder ──────────
                  _buildPhotoArea(memoryState, latestMemory, scale),

                  // ── Warm gradient overlay ──────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),

                  // ── Memory title ────────────────────────────────────────
                  if (displayMemory != null)
                    Positioned(
                      bottom: 20 * scale,
                      left: 20 * scale,
                      right: 20 * scale,
                      child: Text(
                        displayMemory.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2 * scale),
                              blurRadius: 4 * scale,
                              color: Colors.black,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Supportive action section ─────────────────────────────────
          Padding(
            padding: EdgeInsets.all(20 * scale),
            child: Column(
              children: [
                Text(
                  displayMemory != null
                      ? '💝 Tap to relive this memory'
                      : '📸 No memories added yet',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16 * scale),
                SizedBox(
                  width: double.infinity,
                  height: 56 * scale,
                  child: ElevatedButton(
                    onPressed: onViewDay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade50,
                      foregroundColor: Colors.indigo.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_edu, size: 24 * scale),
                        SizedBox(width: 10 * scale),
                        Text(
                          'View My Memories',
                          style: TextStyle(
                            fontSize: 18 * scale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoArea(
    MemoryListState? memoryState,
    dynamic latestMemory,
    double scale,
  ) {
    // Still loading
    if (memoryState == null || memoryState.isLoading) {
      return Container(
        color: Colors.indigo.shade50,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Has a photo URL → show real image from storage
    if (latestMemory?.imageUrl != null &&
        (latestMemory!.imageUrl as String).isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: latestMemory.imageUrl as String,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.indigo.shade50,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => _placeholder(scale),
      );
    }

    // No photo available → warm illustrated placeholder
    return _placeholder(scale);
  }

  Widget _placeholder(double scale) {
    return Container(
      color: Colors.indigo.shade50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64 * scale,
            color: Colors.indigo.shade200,
          ),
          SizedBox(height: 8 * scale),
          Text(
            'Memories will appear here',
            style: TextStyle(
              color: Colors.indigo.shade300,
              fontSize: 14 * scale,
            ),
          ),
        ],
      ),
    );
  }
}
