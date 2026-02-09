import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../features/linking/data/models/invite_code.dart';
import '../../../../features/linking/presentation/controllers/link_controller.dart';

class CaregiverAccessScreen extends ConsumerStatefulWidget {
  const CaregiverAccessScreen({super.key});

  @override
  ConsumerState<CaregiverAccessScreen> createState() =>
      _CaregiverAccessScreenState();
}

class _CaregiverAccessScreenState extends ConsumerState<CaregiverAccessScreen> {
  InviteCode? _currentCode;

  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(linkedProfilesProvider);
    final linkState = ref.watch(linkControllerProvider);

    ref.listen(linkControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Caregiver Access'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGenerateSection(linkState.isLoading),
            const SizedBox(height: 32),
            const Text(
              'Linked Caregivers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            linksAsync.when(
              data: (links) {
                if (links.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('No caregivers linked yet.'),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: links.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final link = links[index];
                    return ListTile(
                      tileColor: Colors.teal.shade50,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(link.relatedProfile?.fullName ?? 'Unknown'),
                      subtitle: Text(
                          'Linked on ${DateFormat.yMMMd().format(link.createdAt)}'),
                      trailing: IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          // Confirm
                          showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                    title: const Text('Remove Access?'),
                                    content: Text(
                                        'Are you sure you want to remove ${link.relatedProfile?.fullName}? They will no longer see your data.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(c),
                                          child: const Text('Cancel')),
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(c);
                                            ref
                                                .read(linkControllerProvider
                                                    .notifier)
                                                .removeLink(link.id);
                                          },
                                          child: const Text('Remove',
                                              style: TextStyle(
                                                  color: Colors.red))),
                                    ],
                                  ));
                        },
                      ),
                    );
                  },
                );
              },
              error: (e, st) => Center(child: Text('Error: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateSection(bool isLoading) {
    if (_currentCode != null &&
        !_currentCode!.isExpired &&
        !_currentCode!.isUsed) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          children: [
            const Text('Share this code with your caregiver',
                style: TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 16),
            Text(
              _currentCode!.code,
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: Colors.blue),
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: _currentCode!.code,
              version: QrVersions.auto,
              size: 150.0,
              gapless: false,
            ),
            const SizedBox(height: 16),
            Text(
              'Expires in ${_currentCode!.expiresAt.difference(DateTime.now()).inHours} hours',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _currentCode!.code));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')));
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Code'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Icon(Icons.security, size: 64, color: Colors.teal),
        const SizedBox(height: 16),
        const Text(
          'Secure Linking',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Generate a code to allow a caregiver to access your health data securely.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        isLoading
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final code = await ref
                        .read(linkControllerProvider.notifier)
                        .generateCode();
                    if (code != null) {
                      setState(() => _currentCode = code);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Generate Access Code'),
                ),
              ),
      ],
    );
  }
}
