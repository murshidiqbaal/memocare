import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/biometric_providers.dart';

/// Modal dialog shown immediately after a successful PASSWORD login.
///
/// Asks the patient in plain language:
///   "Would you like to use your fingerprint next time?"
///
/// Dementia-friendly UX:
///   - Huge icons, minimal text
///   - Simple YES / NOT NOW answer
///   - No technical language
class EnableBiometricDialog extends ConsumerStatefulWidget {
  final String patientId;

  const EnableBiometricDialog({super.key, required this.patientId});

  @override
  ConsumerState<EnableBiometricDialog> createState() =>
      _EnableBiometricDialogState();
}

class _EnableBiometricDialogState extends ConsumerState<EnableBiometricDialog> {
  bool _loading = false;
  String? _message;

  Future<void> _enable() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final error = await ref
        .read(biometricControllerProvider.notifier)
        .enableBiometric(widget.patientId);

    if (!mounted) return;

    if (error == null) {
      // Success
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _loading = false;
      _message = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ──
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.shade50,
              ),
              child: Icon(
                Icons.fingerprint,
                size: 64,
                color: Colors.teal.shade500,
              ),
            ),

            const SizedBox(height: 24),

            // ── Title ──
            Text(
              'Open with Fingerprint?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
            ),

            const SizedBox(height: 12),

            // ── Subtitle ──
            Text(
              'Next time you open MemoCare,\nyou can use your fingerprint instead of your password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),

            // ── Error Message ──
            if (_message != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── YES Button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _enable,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 22),
                label: const Text(
                  'Yes, Use Fingerprint',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── NOT NOW Button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed:
                    _loading ? null : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Not Now',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convenience function to show the dialog and await the patient's choice.
Future<bool?> showEnableBiometricDialog(
  BuildContext context,
  WidgetRef ref,
  String patientId,
) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => EnableBiometricDialog(patientId: patientId),
  );
}
