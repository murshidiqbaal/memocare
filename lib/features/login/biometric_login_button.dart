// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../providers/auth_provider.dart';
// import '../../providers/biometric_providers.dart';

// /// Button used to trigger biometric authentication on login screen
// class BiometricLoginButton extends ConsumerWidget {
//   const BiometricLoginButton({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // We already know it's enabled from the parent FlutterLoginScreen.
//     // Just verify hardware availability.
//     final biometricAvailable =
//         ref.watch(biometricAvailableProvider).valueOrNull ?? true;
//     final biometricState = ref.watch(biometricControllerProvider);
//     final isLoading = biometricState is AsyncLoading;

//     if (!biometricAvailable) {
//       return const SizedBox.shrink();
//     }

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const Text(
//           'Or Login with Biometrics',
//           textAlign: TextAlign.center,
//           style: TextStyle(color: Colors.grey, fontSize: 13),
//         ),
//         const SizedBox(height: 16),
//         InkWell(
//           borderRadius: BorderRadius.circular(40),
//           onTap: isLoading
//               ? null
//               : () async {
//                   final error = await ref
//                       .read(biometricControllerProvider.notifier)
//                       .loginWithBiometric();

//                   if (error != null && context.mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text(error),
//                         backgroundColor: Colors.deepOrange,
//                       ),
//                     );
//                   } else if (context.mounted) {
//                     // Force refresh profile so GoRouter redirect picks it up immediately
//                     ref.invalidate(userProfileProvider);

//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Welcome back!'),
//                         backgroundColor: Colors.teal,
//                       ),
//                     );
//                   }
//                 },
//           child: Container(
//             width: 80,
//             height: 80,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.white,
//               border: Border.all(
//                 color: isLoading ? Colors.teal.shade50 : Colors.teal.shade100,
//                 width: 2,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.teal.withOpacity(0.15),
//                   blurRadius: 15,
//                   spreadRadius: 2,
//                 ),
//               ],
//             ),
//             child: isLoading
//                 ? const Center(
//                     child: CircularProgressIndicator(
//                     strokeWidth: 3,
//                     color: Colors.teal,
//                   ))
//                 : const Icon(
//                     Icons.fingerprint,
//                     size: 48,
//                     color: Colors.teal,
//                   ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         Text(
//           isLoading ? 'Opening...' : 'Login with Fingerprint',
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: isLoading ? Colors.grey : Colors.teal.shade700,
//           ),
//         ),
//       ],
//     );
//   }
// }
