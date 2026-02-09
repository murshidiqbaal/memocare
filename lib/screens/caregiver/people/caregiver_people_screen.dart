import 'package:flutter/material.dart';
import '../../../../data/models/person.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'people_viewmodel.dart';
import 'widgets/people_card_edit_form.dart';
import 'widgets/people_card_list_item.dart';

class CaregiverPeopleScreen extends ConsumerWidget {
  final String patientId;

  const CaregiverPeopleScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(peopleViewModelProvider(patientId));
    final viewModel = ref.read(peopleViewModelProvider(patientId).notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage People'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              viewModel.refresh();
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Syncing...')));
            },
          )
        ],
      ),
      body: state.isLoading && state.people.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.people.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.people.length,
                  itemBuilder: (context, index) {
                    final person = state.people[index];
                    return PeopleCardListItem(
                      person: person,
                      onEdit: () => _showEditForm(context, person, viewModel),
                      onDelete: () =>
                          _confirmDelete(context, person, viewModel),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditForm(context, null, viewModel),
        label: const Text('Add Person'),
        icon: const Icon(Icons.person_add),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No people added yet.',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Add family members and friends\nto help your loved one remember.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  void _showEditForm(
      BuildContext context, Person? person, PeopleViewModel viewModel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PeopleCardEditForm(
          existingPerson: person,
          patientId: patientId,
          onSave: (newPerson) {
            if (person == null) {
              viewModel.addPerson(newPerson);
            } else {
              viewModel.updatePerson(newPerson);
            }
          },
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, Person person, PeopleViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Person?'),
        content: Text('Are you sure you want to remove ${person.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              viewModel.deletePerson(person.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
