import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/emergency_alert_provider.dart';

/// Full-screen SOS countdown dialog
/// Shows a 5-second countdown with cancel option
/// Automatically sends SOS when countdown reaches 0
class SOSCountdownDialog extends ConsumerWidget {
  const SOSCountdownDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosState = ref.watch(emergencySOSControllerProvider);
    final controller = ref.read(emergencySOSControllerProvider.notifier);

    return Dialog.fullscreen(
      backgroundColor: Colors.red.shade900.withOpacity(0.98),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Warning Icon
              _buildWarningIcon(sosState),

              const SizedBox(height: 40),

              // Title
              const Text(
                'EMERGENCY ALERT',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Status Message
              _buildStatusMessage(sosState),

              const SizedBox(height: 60),

              // Countdown or Status
              _buildCountdownDisplay(sosState),

              const SizedBox(height: 60),

              // Action Buttons
              _buildActionButtons(context, sosState, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningIcon(EmergencySOSState state) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.scale(
          scale:
              state is EmergencySOSCountdown ? 1.0 + (0.1 * (1 - value)) : 1.0,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade300.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              state is EmergencySOSSent
                  ? Icons.check_circle
                  : state is EmergencySOSCancelled
                      ? Icons.cancel
                      : state is EmergencySOSError
                          ? Icons.error
                          : Icons.warning_rounded,
              size: 80,
              color: state is EmergencySOSSent
                  ? Colors.green.shade700
                  : state is EmergencySOSCancelled
                      ? Colors.orange.shade700
                      : Colors.red.shade700,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusMessage(EmergencySOSState state) {
    String message;
    Color color = Colors.white;

    if (state is EmergencySOSCountdown) {
      message = 'Sending emergency alert to your caregiver...';
    } else if (state is EmergencySOSSending) {
      message = 'Sending alert...';
    } else if (state is EmergencySOSSent) {
      message = 'Alert sent successfully!';
      color = Colors.green.shade200;
    } else if (state is EmergencySOSCancelled) {
      message = 'Alert cancelled';
      color = Colors.orange.shade200;
    } else if (state is EmergencySOSError) {
      message = 'Failed to send alert';
      color = Colors.red.shade200;
    } else {
      message = 'Preparing to send alert...';
    }

    return Text(
      message,
      style: TextStyle(
        fontSize: 22,
        color: color,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCountdownDisplay(EmergencySOSState state) {
    if (state is EmergencySOSCountdown) {
      return TweenAnimationBuilder<double>(
        key: ValueKey(state.seconds),
        tween: Tween(begin: 1.2, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${state.seconds}',
                  style: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else if (state is EmergencySOSSending) {
      return const SizedBox(
        width: 80,
        height: 80,
        child: CircularProgressIndicator(
          strokeWidth: 6,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (state is EmergencySOSSent) {
      return const Icon(
        Icons.check_circle_outline,
        size: 100,
        color: Colors.white,
      );
    } else if (state is EmergencySOSCancelled) {
      return const Icon(
        Icons.cancel_outlined,
        size: 100,
        color: Colors.white,
      );
    } else if (state is EmergencySOSError) {
      return Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 100,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            state.message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButtons(
    BuildContext context,
    EmergencySOSState state,
    EmergencySOSController controller,
  ) {
    if (state is EmergencySOSCountdown) {
      return _buildCancelButton(context, controller);
    } else if (state is EmergencySOSSent ||
        state is EmergencySOSCancelled ||
        state is EmergencySOSError) {
      return _buildCloseButton(context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildCancelButton(
    BuildContext context,
    EmergencySOSController controller,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: () {
          controller.cancelCountdown();
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        child: const Text(
          'CANCEL',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        child: const Text(
          'CLOSE',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
