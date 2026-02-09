import 'package:flutter/material.dart';

/// Emergency SOS Card - Separated emergency action for safety
///
/// Design principles:
/// - Visually distinct from normal actions
/// - Strong red color hierarchy
/// - Large, clear emergency messaging
/// - Instant recognition for crisis situations
class EmergencySOSCard extends StatelessWidget {
  final VoidCallback onTap;

  const EmergencySOSCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.red.shade300,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Emergency Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sos,
                  size: 36,
                  color: Colors.red.shade700,
                ),
              ),

              const SizedBox(width: 20),

              // Emergency Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Help',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to alert your caregiver',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 20,
                color: Colors.red.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
