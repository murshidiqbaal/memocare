import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/person.dart';
import '../../../../data/repositories/people_repository.dart';
import '../../../../providers/service_providers.dart';

class PeopleState {
  final List<Person> people;
  final bool isLoading;

  PeopleState({this.people = const [], this.isLoading = false});
}

class PeopleViewModel extends StateNotifier<PeopleState> {
  final PeopleRepository _repository;
  final String patientId;

  PeopleViewModel(this._repository, this.patientId) : super(PeopleState()) {
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    state = PeopleState(isLoading: true, people: state.people);
    final people = await _repository.getPeople(patientId);
    state = PeopleState(people: people, isLoading: false);
  }

  Future<void> addPerson(Person person) async {
    // Optimistic update
    state = PeopleState(people: [...state.people, person], isLoading: false);
    await _repository.addPerson(person);
    // Refresh to ensure sync status or URL updates are reflected if instant
    _loadPeople();
  }

  Future<void> updatePerson(Person person) async {
    final updatedList =
        state.people.map((p) => p.id == person.id ? person : p).toList();
    state = PeopleState(people: updatedList, isLoading: false);
    await _repository.updatePerson(person);
    _loadPeople();
  }

  Future<void> deletePerson(String id) async {
    final updatedList = state.people.where((p) => p.id != id).toList();
    state = PeopleState(people: updatedList, isLoading: false);
    await _repository.deletePerson(id);
  }

  Future<void> refresh() async {
    state = PeopleState(people: state.people, isLoading: true);
    await _loadPeople();
  }
}

// Provider needs patientId. Since this is often used in screens where patientId is known (or current user),
// we might need a stored provider or family.
// For Simplicity, we'll assume a "current patient" context or family provider.
final peopleViewModelProvider =
    StateNotifierProvider.family<PeopleViewModel, PeopleState, String>(
        (ref, patientId) {
  final repo = ref.watch(peopleRepositoryProvider);
  return PeopleViewModel(repo, patientId);
});
