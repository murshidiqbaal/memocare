import 'package:flutter/material.dart';

class CaregiverAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String patientName;
  final bool isOffline;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  const CaregiverAppBar({
    super.key,
    required this.patientName,
    required this.isOffline,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Caregiver Dashboard',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Text(
                'Monitoring: $patientName',
                style: TextStyle(
                  color: Colors.teal.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.teal),
            ],
          ),
        ],
      ),
      actions: [
        if (isOffline)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.wifi_off, color: Colors.orange),
          ),
        IconButton(
          onPressed: onNotificationTap,
          icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
        ),
        InkWell(
          onTap: onProfileTap,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.teal.shade100,
              child: const Text('CG', style: TextStyle(color: Colors.teal)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);
}
