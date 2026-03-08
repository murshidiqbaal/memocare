import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/emergency_alert_provider.dart';
import '../../widgets/sos_countdown_dialog.dart';

class CurvedBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CurvedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          /// Bottom Navigation Row
          Row(
            children: [
              Expanded(
                child: _NavBarItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),

              Expanded(
                child: _NavBarItem(
                  icon: Icons.photo_album_rounded,
                  label: 'Memories',
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),

              /// Space for SOS
              const SizedBox(width: 70),

              Expanded(
                child: _NavBarItem(
                  icon: Icons.videogame_asset_rounded,
                  label: 'Games',
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),

              Expanded(
                child: _NavBarItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
              ),
            ],
          ),

          /// SOS Button
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 35,
            top: -25,
            child: _SOSButton(
              onPressed: () => _handleSOSPress(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSOSPress(BuildContext context, WidgetRef ref) {
    ref.read(emergencySOSControllerProvider.notifier).startCountdown();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SOSCountdownDialog(),
    );
  }
}

// void _handleSOSPress(BuildContext context, WidgetRef ref) {
//   // Start countdown
//   ref.read(emergencySOSControllerProvider.notifier).startCountdown();

//   // Show countdown dialog
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) => const SOSCountdownDialog(),
//   );
// }

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26,
            color: isSelected ? Colors.teal : Colors.grey.shade600,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.teal : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SOSButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _SOSButton({required this.onPressed});

  @override
  State<_SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<_SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: GestureDetector(
            onTap: widget.onPressed,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade600,
                    Colors.red.shade800,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emergency, color: Colors.white, size: 28),
                  SizedBox(height: 2),
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
