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
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12 * scale),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: 24 * scale, vertical: 20 * scale),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12 * scale),
            border: Border.all(
              color: Colors.red.shade300,
              width:
                  2, // Border width usually safe to keep fixed or minimal scaling
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.15),
                blurRadius: 12 * scale,
                offset: Offset(0, 4 * scale),
              ),
            ],
          ),
          child: Row(
            children: [
              // Emergency Icon
              Container(
                padding: EdgeInsets.all(14 * scale),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sos,
                  size: 36 * scale,
                  color: Colors.red.shade700,
                ),
              ),

              SizedBox(width: 20 * scale),

              // Emergency Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Help',
                      style: TextStyle(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      'Tap to alert your caregiver',
                      style: TextStyle(
                        fontSize: 15 * scale,
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
                size: 20 * scale,
                color: Colors.red.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
