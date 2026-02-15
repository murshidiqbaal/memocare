import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/caregiver_patients_provider.dart';

class ConnectPatientScreen extends ConsumerStatefulWidget {
  const ConnectPatientScreen({super.key});

  @override
  ConsumerState<ConnectPatientScreen> createState() =>
      _ConnectPatientScreenState();
}

class _ConnectPatientScreenState extends ConsumerState<ConnectPatientScreen> {
  final _codeController = TextEditingController();
  bool _isConnecting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an invite code')),
      );
      return;
    }

    setState(() => _isConnecting = true);
    try {
      await ref
          .read(caregiverConnectionControllerProvider.notifier)
          .connectUsingInviteCode(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Successfully connected to patient!'),
              backgroundColor: Colors.teal),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to connect: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add New Patient'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(32 * scale),
        child: Column(
          children: [
            Icon(Icons.vpn_key_outlined,
                size: 80 * scale, color: Colors.teal.shade200),
            SizedBox(height: 24 * scale),
            const Text(
              'Enter Invite Code',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12 * scale),
            Text(
              'Ask your patient or their family to generate an invite code and enter it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            SizedBox(height: 40 * scale),

            // Code Entry
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4),
              decoration: InputDecoration(
                hintText: 'ABCD-1234',
                hintStyle: TextStyle(
                    color: Colors.grey.shade300, fontSize: 24 * scale),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 20 * scale),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 40 * scale),

            // Connect Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _handleConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 18 * scale),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isConnecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('CONNECT TO PATIENT',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            SizedBox(height: 40 * scale),
            Text(
              'Security Notice: This will link your caregiver account to the patient\'s health records and location data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12 * scale,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
