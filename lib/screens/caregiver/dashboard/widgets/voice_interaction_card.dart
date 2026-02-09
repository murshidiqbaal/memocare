import 'package:flutter/material.dart';
import '../../../../../data/models/voice_query.dart';
import 'package:intl/intl.dart';

/// Voice Interaction Monitoring Card
/// Shows recent patient voice questions and AI responses
class VoiceInteractionCard extends StatelessWidget {
  final List<VoiceQuery> recentInteractions;
  final VoidCallback onViewAllPressed;

  const VoiceInteractionCard({
    super.key,
    required this.recentInteractions,
    required this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.mic, color: Colors.teal.shade600, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Voice Interactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onViewAllPressed,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.teal.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Recent interactions
          if (recentInteractions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No voice interactions yet',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...recentInteractions.take(3).map((interaction) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VoiceInteractionItem(interaction: interaction),
              );
            }).toList(),

          // Last interaction time
          if (recentInteractions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Last interaction: ${_formatTime(recentInteractions.first.createdAt)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, h:mm a').format(time);
    }
  }
}

/// Individual voice interaction item
class _VoiceInteractionItem extends StatelessWidget {
  final VoiceQuery interaction;

  const _VoiceInteractionItem({required this.interaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.person, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  interaction.queryText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Response
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.assistant, color: Colors.teal.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  interaction.responseText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Timestamp
          Text(
            _formatTimestamp(interaction.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    return DateFormat('MMM d, h:mm a').format(time);
  }
}
