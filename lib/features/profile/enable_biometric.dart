// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../providers/auth_provider.dart';
// import '../../providers/biometric_providers.dart';

// /// A toggle switch for the profile settings to enable/disable biometric login.
// class EnableBiometricSwitch extends ConsumerWidget {
//   final bool initialValue;

//   const EnableBiometricSwitch({super.key, required this.initialValue});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final biometricState = ref.watch(biometricControllerProvider);
//     final isLoading = biometricState is AsyncLoading;

//     // Watch current local preference
//     final isEnabledAsync = ref.watch(biometricEnabledProvider);
//     final user = ref.watch(currentUserProvider);

//     return isEnabledAsync.when(
//       data: (isEnabled) => SwitchListTile(
//         title: const Text('Fingerprint Login'),
//         subtitle: const Text('Use fingerprint to skip password'),
//         secondary: isLoading
//             ? const SizedBox(
//                 width: 24, height: 24, child: CircularProgressIndicator())
//             : const Icon(Icons.fingerprint),
//         value: isEnabled,
//         onChanged: (isLoading || user == null)
//             ? null
//             : (value) async {
//                 final messenger = ScaffoldMessenger.of(context);
//                 String? error;

//                 if (value) {
//                   error = await ref
//                       .read(biometricControllerProvider.notifier)
//                       .enableBiometric(user.id);
//                 } else {
//                   await ref
//                       .read(biometricControllerProvider.notifier)
//                       .disableBiometric(user.id);
//                 }

//                 if (error != null) {
//                   messenger.showSnackBar(SnackBar(content: Text(error)));
//                 } else {
//                   // Refresh the local preference state
//                   ref.invalidate(biometricEnabledProvider);
//                   messenger.showSnackBar(
//                     SnackBar(
//                       content: Text(value
//                           ? 'Fingerprint login enabled'
//                           : 'Fingerprint login disabled'),
//                     ),
//                   );
//                 }
//               },
//         activeColor: Colors.teal,
//       ),
//       loading: () => const ListTile(
//         title: Text('Fingerprint Login'),
//         trailing: CircularProgressIndicator(),
//       ),
//       error: (_, __) => const ListTile(
//         title: Text('Fingerprint Login'),
//         trailing: Icon(Icons.error_outline, color: Colors.red),
//       ),
//     );
//   }
// }
