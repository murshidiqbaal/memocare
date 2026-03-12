import 'package:memocare/providers/caregiver_patients_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memocare/data/models/patient.dart';

// import '../../../providers/caregiver_patients_provider.dart';

class ConnectPatientScreen extends ConsumerStatefulWidget {
  const ConnectPatientScreen({super.key});

  @override
  ConsumerState<ConnectPatientScreen> createState() =>
      _ConnectPatientScreenState();
}

class _ConnectPatientScreenState extends ConsumerState<ConnectPatientScreen> {
  final _codeController = TextEditingController();
  bool _isProcessing = false;
  Patient? _foundPatient;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleValidate() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('Please enter an invite code');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
      _foundPatient = null;
    });

    try {
      final patient = await ref
          .read(caregiverConnectionControllerProvider.notifier)
          .validateInviteCode(code);

      if (mounted) {
        setState(() {
          _foundPatient = patient;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleConnect() async {
    if (_foundPatient == null) return;

    setState(() => _isProcessing = true);
    try {
      await ref
          .read(caregiverConnectionControllerProvider.notifier)
          .connectUsingInviteCode(_codeController.text);

      if (mounted) {
        _showSnackBar('Successfully connected to ${_foundPatient!.fullName}!',
            isSuccess: true);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to connect: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.teal : Colors.red,
      ),
    );
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
              'Ask your patient to generate an invite code in their settings and enter it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            SizedBox(height: 40 * scale),

            // Code Entry
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              enabled: !_isProcessing && _foundPatient == null,
              style: TextStyle(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4),
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                hintText: 'ABCD-1234',
                hintStyle: TextStyle(
                    color: Colors.grey.shade300, fontSize: 24 * scale),
                errorText: _error,
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

            if (_foundPatient != null) ...[
              SizedBox(height: 32 * scale),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  children: [
                    const Text('Patient Found:',
                        style: TextStyle(color: Colors.teal)),
                    const SizedBox(height: 8),
                    Text(
                      _foundPatient!.fullName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (_foundPatient!.age != null)
                      Text('Age: ${_foundPatient!.age}',
                          style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    const Text(
                      'Confirm you want to link with this patient.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16 * scale),
              TextButton(
                onPressed: _isProcessing
                    ? null
                    : () => setState(() => _foundPatient = null),
                child: const Text('Use a different code'),
              ),
            ],

            SizedBox(height: 40 * scale),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : (_foundPatient == null
                        ? _handleValidate
                        : _handleConnect),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 18 * scale),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        _foundPatient == null
                            ? 'VALIDATE CODE'
                            : 'CONFIRM CONNECTION',
                        style: const TextStyle(
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
