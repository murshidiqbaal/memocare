import 'package:flutter/material.dart';

class MemoryReviewWidget extends StatelessWidget {
  const MemoryReviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: AssetImage(
                    'assets/images/placeholders/memory_thumb.png'), // Mock
                fit: BoxFit.cover,
              ),
            ),
            child: const Icon(Icons.photo, color: Colors.pinkAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Memory",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Recall session active. Last viewed: 2 hours ago.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {},
                  child: Text(
                    'Review Timeline >',
                    style: TextStyle(
                      color: Colors.pinkAccent.shade700,
                      fontWeight: FontWeight.bold,
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
}
