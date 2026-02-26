import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/call_service.dart';

class PatientListCardCallButton extends ConsumerStatefulWidget {
  final String? phone;
  final String? emergencyPhone;

  const PatientListCardCallButton({
    super.key,
    this.phone,
    this.emergencyPhone,
  });

  @override
  ConsumerState<PatientListCardCallButton> createState() =>
      _PatientListCardCallButtonState();
}

class _PatientListCardCallButtonState
    extends ConsumerState<PatientListCardCallButton> {
  bool _isLoading = false;

  void _handleCall() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    try {
      final callService = ref.read(callServiceProvider);
      await callService.callPatient(
        phone: widget.phone,
        emergencyPhone: widget.emergencyPhone,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleWhatsApp(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final phone = widget.phone ?? widget.emergencyPhone;
    if (phone == null || phone.trim().isEmpty) return;

    final cleanNumber = phone.replaceAll(RegExp(r'\s+'), '');
    final whatsappUri = Uri.parse('https://wa.me/$cleanNumber');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot open WhatsApp or invalid number.'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Patient?'),
        content: const Text(
          'Do you want to initiate a phone call to this patient?',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Call',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final hasNumber = (widget.phone?.trim().isNotEmpty == true) ||
        (widget.emergencyPhone?.trim().isNotEmpty == true);

    return InkWell(
      onTap: hasNumber
          ? () async {
              if (await _showConfirmationDialog(context)) {
                _handleCall();
              }
            }
          : null,
      onLongPress: hasNumber ? () => _handleWhatsApp(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: hasNumber ? Colors.teal.shade50 : Colors.grey.shade200,
          border: Border.all(
            color: hasNumber ? Colors.teal.shade300 : Colors.grey.shade400,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.teal),
              )
            : Icon(
                Icons.phone,
                color: hasNumber ? Colors.teal.shade700 : Colors.grey.shade500,
                size: 24,
              ),
      ),
    );
  }
}
