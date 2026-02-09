import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/linking/presentation/controllers/link_controller.dart';

class AddPatientScreen extends ConsumerStatefulWidget {
  const AddPatientScreen({super.key});

  @override
  ConsumerState<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends ConsumerState<AddPatientScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final linkState = ref.watch(linkControllerProvider);
    final linksAsync = ref.watch(linkedProfilesProvider);

    ref.listen(linkControllerProvider, (previous, next) {
      if (next is AsyncError) {
        showDialog(
            context: context,
            builder: (c) => AlertDialog(
                  title: const Text('Error'),
                  content:
                      Text(next.error.toString().replaceAll('Exception: ', '')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('OK'))
                  ],
                ));
      } else if (next is AsyncData &&
          !next.isLoading &&
          previous is AsyncLoading) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patient linked successfully!')));
        _codeController.clear();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Add Patient')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Enter Invite Code',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ask the patient to generate a code from their settings.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          hintText: '6-digit Code',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.key),
                        ),
                        style: const TextStyle(letterSpacing: 2),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) =>
                            v == null || v.length < 6 ? 'Invalid code' : null,
                      ),
                      const SizedBox(height: 16),
                      linkState.isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    ref
                                        .read(linkControllerProvider.notifier)
                                        .linkPatient(_codeController.text
                                            .toUpperCase()
                                            .trim());
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Link Patient'),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Your Patients',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            linksAsync.when(
                data: (links) {
                  if (links.isEmpty) {
                    return const Center(child: Text('No patients linked yet.'));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: links.length,
                    itemBuilder: (context, index) {
                      final link = links[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(link.relatedProfile?.fullName ?? 'Unknown'),
                        subtitle: Text(
                            'Linked since ${DateFormat.yMMMd().format(link.createdAt)}'),
                        onTap: () {
                          // TODO: Select this patient as current dashboard patient context
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Selected patient.')));
                        },
                      );
                    },
                  );
                },
                error: (e, s) => Text('Error loading patients: $e'),
                loading: () => const Center(child: CircularProgressIndicator()))
          ],
        ),
      ),
    );
  }
}
