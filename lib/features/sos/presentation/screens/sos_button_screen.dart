// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../../../../core/services/sos_service.dart';

// class SosButtonScreen extends ConsumerStatefulWidget {
//   const SosButtonScreen({super.key});

//   @override
//   ConsumerState<SosButtonScreen> createState() => _SosButtonScreenState();
// }

// class _SosButtonScreenState extends ConsumerState<SosButtonScreen> {
//   int _countdown = 5;
//   Timer? _timer;
//   bool _isCountingDown = false;
//   bool _sosSent = false;

//   void _triggerCountdown() {
//     if (_isCountingDown) return;
    
//     setState(() {
//       _isCountingDown = true;
//       _countdown = 5;
//     });

//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_countdown > 1) {
//         setState(() {
//           _countdown--;
//         });
//       } else {
//         _sendSos();
//       }
//     });
//   }

//   Future<void> _sendSos() async {
//     _timer?.cancel();
//     setState(() {
//       _isCountingDown = false;
//       _sosSent = true;
//     });

//     try {
//       await ref.read(sosServiceProvider).triggerManualSos();
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to send SOS: $e')),
//       );
//     }
//   }

//   void _cancelSos() {
//     _timer?.cancel();
//     setState(() {
//       _isCountingDown = false;
//       _countdown = 5;
//     });
//   }

//   Future<void> _callEmergency() async {
//     final Uri callUri = Uri(scheme: 'tel', path: '+911234567890');
//     if (await canLaunchUrl(callUri)) {
//       await launchUrl(callUri);
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch phone dialer')),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: SafeArea(
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // 1. Warning Icon
//               Icon(
//                 Icons.warning_amber_rounded,
//                 size: 80,
//                 color: Colors.red.shade700,
//               )
//               .animate(onPlay: (controller) => controller.repeat())
//               .shake(duration: 500.ms, hz: 3)
//               .then(delay: 1.seconds),

//               const SizedBox(height: 16),
              
//               // 2. Title
//               const Text(
//                 'EMERGENCY SOS',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.red,
//                   letterSpacing: 2,
//                 ),
//               ),
//               const SizedBox(height: 8),
              
//               Text(
//                 _sosSent 
//                   ? 'Alert has been sent to your caregiver.' 
//                   : 'Tap to alert caregiver instantly.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
//               ),

//               const SizedBox(height: 60),

//               // 3. SOS Button
//               if (!_sosSent) ...[
//                 GestureDetector(
//                   onTap: _triggerCountdown,
//                   child: Container(
//                     width: 200,
//                     height: 200,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.red.shade600,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.red.withOpacity(0.4),
//                           blurRadius: 30,
//                           spreadRadius: 10,
//                         ),
//                       ],
//                     ),
//                     child: Center(
//                       child: _isCountingDown
//                         ? Text(
//                             '$_countdown',
//                             style: const TextStyle(
//                               fontSize: 80,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack)
//                         : const Text(
//                             'SOS',
//                             style: TextStyle(
//                               fontSize: 60,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                     ),
//                   ).animate(onPlay: (controller) => controller.repeat(reverse: true))
//                    .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds),
//                 ),
                
//                 const SizedBox(height: 40),

//                 if (_isCountingDown)
//                   TextButton.icon(
//                     onPressed: _cancelSos,
//                     icon: const Icon(Icons.cancel, color: Colors.black54),
//                     label: const Text(
//                       'CANCEL',
//                       style: TextStyle(color: Colors.black54, fontSize: 18),
//                     ),
//                   ),
//               ] else ...[
//                 // Success State Container
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.green.shade50,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(Icons.check_circle, size: 100, color: Colors.green.shade600),
//                 ).animate().scale().fadeIn(),
//               ],

//               const Spacer(),

//               // 4. Emergency Call System Button
//               Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: SizedBox(
//                   width: double.infinity,
//                   height: 60,
//                   child: ElevatedButton.icon(
//                     onPressed: _callEmergency,
//                     icon: const Icon(Icons.phone, size: 28),
//                     label: const Text(
//                       'EMERGENCY CALL',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red.shade900,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
