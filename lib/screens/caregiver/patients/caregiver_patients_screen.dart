import 'package:dementia_care_app/data/models/sos_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/patient.dart';
import '../../../providers/caregiver_patients_provider.dart';
import '../../../providers/sos_messages_provider.dart';
import '../../patient/profile/patient_profile_screen.dart';
import 'add_patient_screen.dart';

class CaregiverPatientsScreen extends ConsumerWidget {
  const CaregiverPatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(connectedPatientsStreamProvider);
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Patients'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Badge showing unread SOS messages
          Consumer(
            builder: (context, ref, child) {
              final unreadCount = ref.watch(unreadSosMessagesCountProvider);
              return unreadCount.when(
                data: (count) {
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications),
                        onPressed: () => _showSosMessages(context, ref),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.all(4 * scale),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPatientScreen()),
          );
        },
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Patient',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: patientsAsync.when(
        data: (patients) {
          if (patients.isEmpty) {
            return _buildEmptyState(context, scale);
          }
          return ListView.builder(
            padding: EdgeInsets.all(20 * scale),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return _buildPatientCard(context, ref, patient, scale);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, double scale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 100 * scale, color: Colors.grey.shade300),
          SizedBox(height: 24 * scale),
          Text(
            'No patients connected yet',
            style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600),
          ),
          SizedBox(height: 12 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40 * scale),
            child: Text(
              'To start monitoring, add a patient using their unique invite code.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14 * scale, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(
      BuildContext context, WidgetRef ref, Patient patient, double scale) {
    final sosMessagesAsync = ref.watch(patientSosMessagesProvider(patient.id));

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16 * scale),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          // Navigate to patient profile
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientProfileScreen(patientId: patient.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Column(
            children: [
              Row(
                children: [
                  // Patient Photo
                  Hero(
                    tag: 'patient_avatar_${patient.id}',
                    child: CircleAvatar(
                      radius: 30 * scale,
                      backgroundColor: Colors.teal.shade50,
                      backgroundImage: patient.profilePhotoUrl != null
                          ? NetworkImage(patient.profilePhotoUrl!)
                          : null,
                      child: patient.profilePhotoUrl == null
                          ? Icon(Icons.person, color: Colors.teal.shade300)
                          : null,
                    ),
                  ),
                  SizedBox(width: 16 * scale),

                  // Patient Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.fullName ?? 'Unnamed Patient',
                          style: TextStyle(
                              fontSize: 18 * scale,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4 * scale),
                        if (patient.phoneNumber != null)
                          Text(
                            patient.phoneNumber!,
                            style: TextStyle(
                                fontSize: 14 * scale,
                                color: Colors.grey.shade600),
                          ),
                        SizedBox(height: 4 * scale),
                        Text(
                          'Linked since: ${patient.linkedAt != null ? patient.linkedAt!.toLocal().toString().split(' ')[0] : 'Unknown'}',
                          style: TextStyle(
                              fontSize: 12 * scale,
                              color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  IconButton(
                    icon: const Icon(Icons.map_outlined, color: Colors.teal),
                    onPressed: () => context.push(
                      '/caregiver-patient-map/${patient.id}?name=${Uri.encodeComponent(patient.fullName ?? 'Patient')}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.link_off, color: Colors.redAccent),
                    onPressed: () => _confirmRemove(context, ref, patient),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),

              // SOS Messages Section
              sosMessagesAsync.when(
                data: (messages) {
                  final unreadMessages =
                      messages.where((m) => !m.isMarkedAsRead).toList();
                  if (unreadMessages.isNotEmpty) {
                    return _buildSosMessagesBanner(
                        context, ref, patient, unreadMessages, scale);
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (err, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSosMessagesBanner(BuildContext context, WidgetRef ref,
      Patient patient, List<SosMessage> messages, double scale) {
    return Container(
      margin: EdgeInsets.only(top: 12 * scale),
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(
          top: BorderSide(color: Colors.red.shade300, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.redAccent, size: 24),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${messages.length} Alert${messages.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                if (messages.isNotEmpty)
                  Text(
                    messages.first.messageText ?? 'New alert received',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12 * scale, color: Colors.red[700]),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8 * scale),
          InkWell(
            onTap: () =>
                _showPatientSosMessages(context, ref, patient, messages, scale),
            child: Icon(Icons.arrow_forward_ios,
                color: Colors.redAccent, size: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _showSosMessages(BuildContext context, WidgetRef ref) async {
    final allMessages = ref.watch(allUnreadSosMessagesProvider);

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: allMessages.when(
            data: (messages) {
              if (messages.isEmpty) {
                return SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 60, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'No alerts',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All alerts have been marked as read',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unread Alerts',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildSosMessageTile(context, ref, message);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              width: 300,
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Error loading alerts'),
                  const SizedBox(height: 8),
                  Text(err.toString(), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPatientSosMessages(BuildContext context, WidgetRef ref,
      Patient patient, List<SosMessage> messages, double scale) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(16.0 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20 * scale,
                    backgroundColor: Colors.teal.shade50,
                    backgroundImage: patient.profilePhotoUrl != null
                        ? NetworkImage(patient.profilePhotoUrl!)
                        : null,
                    child: patient.profilePhotoUrl == null
                        ? Icon(Icons.person, color: Colors.teal.shade300)
                        : null,
                  ),
                  SizedBox(width: 12 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${patient.fullName ?? 'Patient'} - Alerts',
                          style: TextStyle(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${messages.length} unread',
                          style: TextStyle(
                              fontSize: 12 * scale, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildSosMessageCard(context, ref, message, scale);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Mark all as read for this patient
                      for (var message in messages) {
                        ref
                            .read(sosMessagesControllerProvider.notifier)
                            .markAsRead(message.id);
                      }
                      Navigator.pop(context);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text('Mark All as Read',
                        style: TextStyle(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSosMessageTile(
      BuildContext context, WidgetRef ref, SosMessage message) {
    return ListTile(
      title: Text(message.patientName ?? 'Unknown Patient'),
      subtitle: Text(
        message.messageText ?? 'Alert received',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.check, color: Colors.teal),
        onPressed: () {
          ref
              .read(sosMessagesControllerProvider.notifier)
              .markAsRead(message.id);
        },
      ),
    );
  }

  Widget _buildSosMessageCard(
      BuildContext context, WidgetRef ref, SosMessage message, double scale) {
    return Card(
      margin: EdgeInsets.only(bottom: 12 * scale),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Mark as read when tapped
          ref
              .read(sosMessagesControllerProvider.notifier)
              .markAsRead(message.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.messageText ?? 'Alert',
                          style: TextStyle(
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  if (!message.isMarkedAsRead)
                    Container(
                      padding: EdgeInsets.all(4 * scale),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notification_important,
                          size: 16 * scale, color: Colors.white),
                    ),
                ],
              ),
              SizedBox(height: 12 * scale),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!message.isMarkedAsRead)
                    ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(sosMessagesControllerProvider.notifier)
                            .markAsRead(message.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(
                            horizontal: 12 * scale, vertical: 8 * scale),
                      ),
                      icon: const Icon(Icons.check,
                          size: 16, color: Colors.white),
                      label: const Text(
                        'Mark as Read',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 16 * scale, color: Colors.green),
                        SizedBox(width: 4 * scale),
                        Text(
                          'Read',
                          style: TextStyle(
                            fontSize: 12 * scale,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Connection'),
        content: Text(
            'Are you sure you want to stop monitoring ${patient.fullName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(caregiverConnectionControllerProvider.notifier)
          .removeConnection(patient.id);
    }
  }
}
