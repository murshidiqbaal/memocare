import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/auth_provider.dart';
import '../../data/models/caregiver_patient_link.dart';
import '../../data/models/invite_code.dart';
import '../../data/repositories/link_repository.dart';

// States
final activeInviteCodeProvider =
    FutureProvider.autoDispose<InviteCode?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  // This would ideally just verify if there's an active one in DB without generating new one
  // But for simple use, we don't have a 'get' method, only 'generate'.
  // Let's assume the UI calls generate manually.
  return null;
});

final linkedProfilesProvider =
    FutureProvider.autoDispose<List<CaregiverPatientLink>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final profile = await ref.watch(userProfileProvider.future);
  if (user == null || profile == null) return [];

  final repo = ref.watch(linkRepositoryProvider);
  if (profile.role == 'patient') {
    return repo.getLinkedCaregivers(user.id);
  } else if (profile.role == 'caregiver') {
    return repo.getLinkedPatients(user.id);
  }
  return [];
});

class LinkController extends StateNotifier<AsyncValue<void>> {
  final LinkRepository _repo;
  final Ref _ref;

  LinkController(this._repo, this._ref) : super(const AsyncData(null));

  Future<InviteCode?> generateCode() async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('Not logged in');

      final code = await _repo.generateInviteCode(user.id);
      state = const AsyncData(null);
      return code;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> linkPatient(String code) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('Not logged in');

      await _repo.linkPatient(user.id, code);
      state = const AsyncData(null);
      // Refresh list
      _ref.invalidate(linkedProfilesProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> removeLink(String linkId) async {
    state = const AsyncLoading();
    try {
      await _repo.removeCaregiver(linkId);
      state = const AsyncData(null);
      _ref.invalidate(linkedProfilesProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final linkControllerProvider =
    StateNotifierProvider<LinkController, AsyncValue<void>>((ref) {
  return LinkController(ref.watch(linkRepositoryProvider), ref);
});
