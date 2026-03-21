import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the currently selected tab index for the patient bottom nav.
/// 0 = Home, 1 = Memories, 2 = Games, 3 = Profile
final patientNavigationProvider = StateProvider<int>((ref) => 0);
