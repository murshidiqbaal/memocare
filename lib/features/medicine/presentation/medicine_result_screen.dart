// // lib/features/medicine_recognition/screens/medicine_result_screen.dart

// import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../models/medicine_models.dart';
// import '../../../providers/medicine_recognition_provider.dart';

// // Reuse same design tokens
// class _DS {
//   static const Color bgDeep = Color(0xFF0F172A);
//   static const Color bgCard = Color(0xFF1E293B);
//   static const Color bgCardAlt = Color(0xFF263548);
//   static const Color accentBlue = Color(0xFF38BDF8);
//   static const Color accentTeal = Color(0xFF2DD4BF);
//   static const Color accentAmber = Color(0xFFFBBF24);
//   static const Color accentPurple = Color(0xFFA78BFA);
//   static const Color textPrimary = Color(0xFFF1F5F9);
//   static const Color textSecondary = Color(0xFF94A3B8);
//   static const Color successGreen = Color(0xFF34D399);
//   static const Color errorRed = Color(0xFFF87171);
//   static const Color warningOrange = Color(0xFFFB923C);

//   static const double radiusLg = 24;
//   static const double radiusMd = 16;
//   static const double radiusSm = 12;

//   static const double fontXXL = 32;
//   static const double fontXL = 26;
//   static const double fontLg = 20;
//   static const double fontMd = 17;
//   static const double fontSm = 14;

//   static const double buttonHeight = 68;
// }

// class MedicineResultScreen extends ConsumerStatefulWidget {
//   const MedicineResultScreen({super.key, required this.medicine});

//   final MedicineInfo medicine;

//   @override
//   ConsumerState<MedicineResultScreen> createState() =>
//       _MedicineResultScreenState();
// }

// class _MedicineResultScreenState extends ConsumerState<MedicineResultScreen>
//     with TickerProviderStateMixin {
//   // Selected reminder times
//   final List<ReminderTime> _selectedTimes = [];
//   bool _showReminderSetup = false;

//   late final AnimationController _entryCtrl;
//   late final Animation<Offset> _slideAnim;
//   late final Animation<double> _fadeAnim;

//   @override
//   void initState() {
//     super.initState();
//     _entryCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 700),
//     )..forward();

//     _slideAnim = Tween<Offset>(
//       begin: const Offset(0, 0.12),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

//     _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
//   }

//   @override
//   void dispose() {
//     _entryCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final reminderState = ref.watch(reminderCreationProvider);

//     ref.listen<ReminderCreationState>(reminderCreationProvider, (_, next) {
//       next.whenOrNull(
//         saved: (_) => _showSuccessDialog(),
//         error: (msg) => _showErrorSnackBar(msg),
//       );
//     });

//     return Scaffold(
//       backgroundColor: _DS.bgDeep,
//       body: SafeArea(
//         child: FadeTransition(
//           opacity: _fadeAnim,
//           child: SlideTransition(
//             position: _slideAnim,
//             child: CustomScrollView(
//               slivers: [
//                 SliverToBoxAdapter(
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildHeader(),
//                         const SizedBox(height: 28),
//                         _buildConfidenceBanner(),
//                         const SizedBox(height: 20),
//                         _buildMedicineCard(),
//                         const SizedBox(height: 20),
//                         if (widget.medicine.instructions.isNotEmpty) ...[
//                           _buildInstructionsCard(),
//                           const SizedBox(height: 20),
//                         ],
//                         if (widget.medicine.warnings.isNotEmpty) ...[
//                           _buildWarningsCard(),
//                           const SizedBox(height: 20),
//                         ],
//                         AnimatedCrossFade(
//                           firstChild: _buildAddReminderPrompt(),
//                           secondChild: _buildReminderSetupCard(reminderState),
//                           crossFadeState: _showReminderSetup
//                               ? CrossFadeState.showSecond
//                               : CrossFadeState.showFirst,
//                           duration: const Duration(milliseconds: 400),
//                         ),
//                         const SizedBox(height: 32),
//                         _buildBottomActions(reminderState),
//                         const SizedBox(height: 32),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ── HEADER ────────────────────────────────────────────────────────────────

//   Widget _buildHeader() {
//     return Row(
//       children: [
//         GestureDetector(
//           onTap: () {
//             ref.read(medicineScanProvider.notifier).reset();
//             ref.read(reminderCreationProvider.notifier).reset();
//             Navigator.of(context).pop();
//           },
//           child: Container(
//             width: 52,
//             height: 52,
//             decoration: BoxDecoration(
//               color: _DS.bgCard,
//               borderRadius: BorderRadius.circular(_DS.radiusSm),
//             ),
//             child: const Icon(
//               Icons.arrow_back_ios_new_rounded,
//               color: _DS.textPrimary,
//               size: 22,
//             ),
//           ),
//         ),
//         const SizedBox(width: 16),
//         const Expanded(
//           child: Text(
//             'Medicine Found',
//             style: TextStyle(
//               color: _DS.textPrimary,
//               fontSize: _DS.fontXL,
//               fontWeight: FontWeight.w700,
//               letterSpacing: -0.5,
//             ),
//           ),
//         ),
//         Container(
//           width: 52,
//           height: 52,
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               colors: [_DS.successGreen, _DS.accentTeal],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(_DS.radiusSm),
//           ),
//           child: const Icon(
//             Icons.check_circle_rounded,
//             color: Colors.white,
//             size: 28,
//           ),
//         ),
//       ],
//     );
//   }

//   // ── CONFIDENCE BANNER ─────────────────────────────────────────────────────

//   Widget _buildConfidenceBanner() {
//     final conf = widget.medicine.confidence;
//     final Color color;
//     final String label;
//     final IconData icon;

//     switch (conf) {
//       case RecognitionConfidence.high:
//         color = _DS.successGreen;
//         label = 'Clearly identified ✓';
//         icon = Icons.verified_rounded;
//         break;
//       case RecognitionConfidence.medium:
//         color = _DS.accentAmber;
//         label = 'Probably correct — please verify';
//         icon = Icons.info_rounded;
//         break;
//       case RecognitionConfidence.low:
//         color = _DS.errorRed;
//         label = 'Not sure — please check with caregiver';
//         icon = Icons.warning_rounded;
//         break;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(_DS.radiusMd),
//         border: Border.all(color: color.withOpacity(0.4), width: 1.5),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: color, size: 26),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               label,
//               style: TextStyle(
//                 color: color,
//                 fontSize: _DS.fontMd,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── MEDICINE CARD ─────────────────────────────────────────────────────────

//   Widget _buildMedicineCard() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: _DS.bgCard,
//         borderRadius: BorderRadius.circular(_DS.radiusLg),
//         border: Border.all(
//           color: _DS.accentBlue.withOpacity(0.2),
//           width: 1.5,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 56,
//                 height: 56,
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [_DS.accentBlue, _DS.accentTeal],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: const Icon(
//                   Icons.medication_rounded,
//                   color: Colors.white,
//                   size: 30,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Medicine Name',
//                       style: TextStyle(
//                         color: _DS.textSecondary,
//                         fontSize: _DS.fontSm,
//                         fontWeight: FontWeight.w500,
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       widget.medicine.name,
//                       style: const TextStyle(
//                         color: _DS.textPrimary,
//                         fontSize: _DS.fontXL,
//                         fontWeight: FontWeight.w800,
//                         letterSpacing: -0.3,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           const Divider(color: Color(0xFF2D3F55), thickness: 1),
//           const SizedBox(height: 20),
//           // Info grid
//           Row(
//             children: [
//               Expanded(
//                 child: _InfoTile(
//                   icon: Icons.scale_rounded,
//                   label: 'Dosage',
//                   value: widget.medicine.dosage,
//                   valueColor: _DS.accentBlue,
//                 ),
//               ),
//               if (widget.medicine.activeIngredient.isNotEmpty) ...[
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _InfoTile(
//                     icon: Icons.science_rounded,
//                     label: 'Active Ingredient',
//                     value: widget.medicine.activeIngredient,
//                     valueColor: _DS.accentTeal,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//           if (widget.medicine.manufacturer.isNotEmpty) ...[
//             const SizedBox(height: 12),
//             _InfoTile(
//               icon: Icons.business_rounded,
//               label: 'Manufacturer',
//               value: widget.medicine.manufacturer,
//               valueColor: _DS.accentPurple,
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // ── INSTRUCTIONS CARD ─────────────────────────────────────────────────────

//   Widget _buildInstructionsCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: _DS.bgCard,
//         borderRadius: BorderRadius.circular(_DS.radiusLg),
//         border: Border.all(
//           color: _DS.accentTeal.withOpacity(0.25),
//           width: 1.5,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: const [
//               Icon(Icons.receipt_long_rounded, color: _DS.accentTeal, size: 24),
//               SizedBox(width: 10),
//               Text(
//                 'How to Take',
//                 style: TextStyle(
//                   color: _DS.accentTeal,
//                   fontSize: _DS.fontMd,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             widget.medicine.instructions,
//             style: const TextStyle(
//               color: _DS.textPrimary,
//               fontSize: _DS.fontLg,
//               height: 1.6,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── WARNINGS CARD ────────────────────────────────────────────────────────

//   Widget _buildWarningsCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: _DS.warningOrange.withOpacity(0.07),
//         borderRadius: BorderRadius.circular(_DS.radiusLg),
//         border: Border.all(
//           color: _DS.warningOrange.withOpacity(0.35),
//           width: 1.5,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: const [
//               Icon(Icons.warning_amber_rounded,
//                   color: _DS.warningOrange, size: 24),
//               SizedBox(width: 10),
//               Text(
//                 'Warnings',
//                 style: TextStyle(
//                   color: _DS.warningOrange,
//                   fontSize: _DS.fontMd,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           ...widget.medicine.warnings.map(
//             (w) => Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Padding(
//                     padding: EdgeInsets.only(top: 6),
//                     child: CircleAvatar(
//                       radius: 4,
//                       backgroundColor: _DS.warningOrange,
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: Text(
//                       w,
//                       style: const TextStyle(
//                         color: _DS.textPrimary,
//                         fontSize: _DS.fontMd,
//                         height: 1.5,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── ADD REMINDER PROMPT ───────────────────────────────────────────────────

//   Widget _buildAddReminderPrompt() {
//     return _DementiaFriendlyButton(
//       icon: Icons.alarm_add_rounded,
//       label: '⏰  Set a Reminder',
//       subtitle: 'I will remind you to take this medicine',
//       gradient: const LinearGradient(
//         colors: [_DS.accentPurple, Color(0xFF6366F1)],
//         begin: Alignment.centerLeft,
//         end: Alignment.centerRight,
//       ),
//       onTap: () => setState(() => _showReminderSetup = true),
//     );
//   }

//   // ── REMINDER SETUP CARD ───────────────────────────────────────────────────

//   Widget _buildReminderSetupCard(ReminderCreationState reminderState) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: _DS.bgCard,
//         borderRadius: BorderRadius.circular(_DS.radiusLg),
//         border: Border.all(
//           color: _DS.accentPurple.withOpacity(0.3),
//           width: 1.5,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: const [
//               Icon(Icons.alarm_rounded, color: _DS.accentPurple, size: 26),
//               SizedBox(width: 12),
//               Text(
//                 'When to take it?',
//                 style: TextStyle(
//                   color: _DS.textPrimary,
//                   fontSize: _DS.fontLg,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           const Text(
//             'Tap the times you need to take this medicine each day.',
//             style: TextStyle(
//               color: _DS.textSecondary,
//               fontSize: _DS.fontSm,
//               height: 1.5,
//             ),
//           ),
//           const SizedBox(height: 20),
//           // Time chips
//           Wrap(
//             spacing: 10,
//             runSpacing: 10,
//             children: _defaultReminderTimes.map((rt) {
//               final isSelected = _selectedTimes.any(
//                 (t) => t.hour == rt.hour && t.minute == rt.minute,
//               );
//               return _TimeChip(
//                 time: rt,
//                 isSelected: isSelected,
//                 onTap: () => setState(() {
//                   if (isSelected) {
//                     _selectedTimes.removeWhere(
//                         (t) => t.hour == rt.hour && t.minute == rt.minute);
//                   } else {
//                     _selectedTimes.add(rt);
//                   }
//                 }),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 24),
//           // Custom time picker
//           GestureDetector(
//             onTap: _showCustomTimePicker,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
//               decoration: BoxDecoration(
//                 color: _DS.bgCardAlt,
//                 borderRadius: BorderRadius.circular(_DS.radiusSm),
//                 border: Border.all(
//                   color: _DS.accentPurple.withOpacity(0.3),
//                 ),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: const [
//                   Icon(Icons.add_circle_outline_rounded,
//                       color: _DS.accentPurple, size: 22),
//                   SizedBox(width: 8),
//                   Text(
//                     'Add custom time',
//                     style: TextStyle(
//                       color: _DS.accentPurple,
//                       fontSize: _DS.fontMd,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (_selectedTimes.isNotEmpty) ...[
//             const SizedBox(height: 16),
//             Text(
//               '${_selectedTimes.length} time${_selectedTimes.length > 1 ? "s" : ""} selected',
//               style: const TextStyle(
//                 color: _DS.successGreen,
//                 fontSize: _DS.fontSm,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // ── BOTTOM ACTIONS ────────────────────────────────────────────────────────

//   Widget _buildBottomActions(ReminderCreationState reminderState) {
//     final isSaving = reminderState.maybeWhen(
//       saving: () => true,
//       orElse: () => false,
//     );

//     return Column(
//       children: [
//         if (_showReminderSetup) ...[
//           _DementiaFriendlyButton(
//             icon: isSaving ? null : Icons.save_rounded,
//             label: isSaving ? 'Saving...' : '💾  Save Reminder',
//             subtitle: 'I will remind you every day',
//             gradient: const LinearGradient(
//               colors: [_DS.successGreen, _DS.accentTeal],
//               begin: Alignment.centerLeft,
//               end: Alignment.centerRight,
//             ),
//             isLoading: isSaving,
//             isDisabled: _selectedTimes.isEmpty || isSaving,
//             onTap: _selectedTimes.isEmpty ? null : _saveReminder,
//           ),
//           const SizedBox(height: 14),
//         ],
//         _DementiaFriendlyButton(
//           icon: Icons.camera_alt_rounded,
//           label: '📷  Scan Another Medicine',
//           subtitle: 'Take a new photo',
//           gradient: LinearGradient(
//             colors: [
//               _DS.bgCard,
//               _DS.bgCardAlt,
//             ],
//             begin: Alignment.centerLeft,
//             end: Alignment.centerRight,
//           ),
//           borderColor: _DS.accentBlue.withOpacity(0.4),
//           onTap: () {
//             ref.read(medicineScanProvider.notifier).reset();
//             ref.read(reminderCreationProvider.notifier).reset();
//             Navigator.of(context).pop();
//           },
//         ),
//       ],
//     );
//   }

//   // ── HELPERS ───────────────────────────────────────────────────────────────

//   static final List<ReminderTime> _defaultReminderTimes = [
//     const ReminderTime(hour: 7, minute: 0, label: 'Morning'),
//     const ReminderTime(hour: 12, minute: 0, label: 'Midday'),
//     const ReminderTime(hour: 18, minute: 0, label: 'Evening'),
//     const ReminderTime(hour: 21, minute: 0, label: 'Night'),
//   ];

//   Future<void> _showCustomTimePicker() async {
//     final time = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//       builder: (context, child) {
//         return Theme(
//           data: ThemeData.dark().copyWith(
//             colorScheme: const ColorScheme.dark(
//               primary: _DS.accentBlue,
//               surface: _DS.bgCard,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (time != null && mounted) {
//       setState(() {
//         _selectedTimes.add(
//           ReminderTime(
//             hour: time.hour,
//             minute: time.minute,
//             label: 'Custom',
//           ),
//         );
//       });
//     }
//   }

//   Future<void> _saveReminder() async {
//     await ref.read(reminderCreationProvider.notifier).createReminder(
//           medicine: widget.medicine,
//           times: _selectedTimes,
//         );
//   }

//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => _SuccessDialog(
//         medicineName: widget.medicine.name,
//         times: _selectedTimes,
//         onDone: () {
//           Navigator.of(context).pop(); // close dialog
//           Navigator.of(context).pop(); // go back to home
//           ref.read(medicineScanProvider.notifier).reset();
//           ref.read(reminderCreationProvider.notifier).reset();
//         },
//       ),
//     );
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: const TextStyle(fontSize: _DS.fontMd, color: _DS.textPrimary),
//         ),
//         backgroundColor: _DS.bgCard,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(_DS.radiusSm),
//         ),
//       ),
//     );
//   }
// }

// // ── INFO TILE ─────────────────────────────────────────────────────────────────

// class _InfoTile extends StatelessWidget {
//   const _InfoTile({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.valueColor,
//   });

//   final IconData icon;
//   final String label;
//   final String value;
//   final Color valueColor;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: _DS.bgCardAlt,
//         borderRadius: BorderRadius.circular(_DS.radiusSm),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: _DS.textSecondary, size: 16),
//               const SizedBox(width: 6),
//               Text(
//                 label,
//                 style: const TextStyle(
//                   color: _DS.textSecondary,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w500,
//                   letterSpacing: 0.3,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             value,
//             style: TextStyle(
//               color: valueColor,
//               fontSize: _DS.fontMd,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── TIME CHIP ─────────────────────────────────────────────────────────────────

// class _TimeChip extends StatelessWidget {
//   const _TimeChip({
//     required this.time,
//     required this.isSelected,
//     required this.onTap,
//   });

//   final ReminderTime time;
//   final bool isSelected;
//   final VoidCallback onTap;

//   String get _formattedTime {
//     final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
//     final m = time.minute.toString().padLeft(2, '0');
//     final period = time.hour < 12 ? 'AM' : 'PM';
//     return '$h:$m $period';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
//         decoration: BoxDecoration(
//           gradient: isSelected
//               ? const LinearGradient(
//                   colors: [_DS.accentPurple, Color(0xFF6366F1)],
//                 )
//               : null,
//           color: isSelected ? null : _DS.bgCardAlt,
//           borderRadius: BorderRadius.circular(_DS.radiusSm),
//           border: Border.all(
//             color: isSelected
//                 ? Colors.transparent
//                 : _DS.textSecondary.withOpacity(0.3),
//             width: 1.5,
//           ),
//           boxShadow: isSelected
//               ? [
//                   BoxShadow(
//                     color: _DS.accentPurple.withOpacity(0.4),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ]
//               : null,
//         ),
//         child: Column(
//           children: [
//             Text(
//               time.label,
//               style: TextStyle(
//                 color: isSelected ? Colors.white70 : _DS.textSecondary,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               _formattedTime,
//               style: TextStyle(
//                 color: isSelected ? Colors.white : _DS.textPrimary,
//                 fontSize: _DS.fontMd,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── DEMENTIA-FRIENDLY BUTTON ──────────────────────────────────────────────────

// class _DementiaFriendlyButton extends StatefulWidget {
//   const _DementiaFriendlyButton({
//     required this.label,
//     required this.gradient,
//     this.icon,
//     this.subtitle,
//     this.borderColor,
//     this.onTap,
//     this.isLoading = false,
//     this.isDisabled = false,
//   });

//   final IconData? icon;
//   final String label;
//   final String? subtitle;
//   final Gradient gradient;
//   final Color? borderColor;
//   final VoidCallback? onTap;
//   final bool isLoading;
//   final bool isDisabled;

//   @override
//   State<_DementiaFriendlyButton> createState() =>
//       _DementiaFriendlyButtonState();
// }

// class _DementiaFriendlyButtonState extends State<_DementiaFriendlyButton> {
//   bool _pressed = false;

//   @override
//   Widget build(BuildContext context) {
//     final disabled = widget.isDisabled || widget.onTap == null;

//     return GestureDetector(
//       onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
//       onTapUp: disabled
//           ? null
//           : (_) {
//               setState(() => _pressed = false);
//               widget.onTap?.call();
//             },
//       onTapCancel: () => setState(() => _pressed = false),
//       child: AnimatedOpacity(
//         opacity: disabled ? 0.5 : 1.0,
//         duration: const Duration(milliseconds: 200),
//         child: AnimatedScale(
//           scale: _pressed ? 0.97 : 1.0,
//           duration: const Duration(milliseconds: 100),
//           child: Container(
//             height: _DS.buttonHeight,
//             decoration: BoxDecoration(
//               gradient: widget.gradient,
//               borderRadius: BorderRadius.circular(_DS.radiusMd),
//               border: widget.borderColor != null
//                   ? Border.all(color: widget.borderColor!, width: 1.5)
//                   : null,
//               boxShadow: disabled
//                   ? null
//                   : [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.2),
//                         blurRadius: 12,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//             ),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Row(
//                 children: [
//                   if (widget.isLoading)
//                     const SizedBox(
//                       width: 28,
//                       height: 28,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2.5,
//                         color: Colors.white,
//                       ),
//                     )
//                   else if (widget.icon != null)
//                     Icon(widget.icon, color: Colors.white, size: 28),
//                   const SizedBox(width: 14),
//                   Expanded(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           widget.label,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: _DS.fontLg,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                         if (widget.subtitle != null)
//                           Text(
//                             widget.subtitle!,
//                             style: TextStyle(
//                               color: Colors.white.withOpacity(0.7),
//                               fontSize: _DS.fontSm,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                   if (!widget.isLoading)
//                     const Icon(
//                       Icons.arrow_forward_ios_rounded,
//                       color: Colors.white,
//                       size: 18,
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ── SUCCESS DIALOG ────────────────────────────────────────────────────────────

// class _SuccessDialog extends StatefulWidget {
//   const _SuccessDialog({
//     required this.medicineName,
//     required this.times,
//     required this.onDone,
//   });

//   final String medicineName;
//   final List<ReminderTime> times;
//   final VoidCallback onDone;

//   @override
//   State<_SuccessDialog> createState() => _SuccessDialogState();
// }

// class _SuccessDialogState extends State<_SuccessDialog>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//   late final Animation<double> _scaleAnim;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     )..forward();
//     _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   String get _timeSummary {
//     if (widget.times.isEmpty) return '';
//     return widget.times.map((t) {
//       final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
//       final m = t.minute.toString().padLeft(2, '0');
//       final period = t.hour < 12 ? 'AM' : 'PM';
//       return '$h:$m $period';
//     }).join(', ');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       child: ScaleTransition(
//         scale: _scaleAnim,
//         child: Container(
//           padding: const EdgeInsets.all(32),
//           decoration: BoxDecoration(
//             color: _DS.bgCard,
//             borderRadius: BorderRadius.circular(_DS.radiusLg),
//             border: Border.all(
//               color: _DS.successGreen.withOpacity(0.4),
//               width: 2,
//             ),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Checkmark
//               Container(
//                 width: 90,
//                 height: 90,
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [_DS.successGreen, _DS.accentTeal],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: _DS.successGreen.withOpacity(0.4),
//                       blurRadius: 24,
//                       spreadRadius: 4,
//                     ),
//                   ],
//                 ),
//                 child: const Icon(Icons.check_rounded,
//                     color: Colors.white, size: 48),
//               ),
//               const SizedBox(height: 24),
//               const Text(
//                 'Reminder Set! 🎉',
//                 style: TextStyle(
//                   color: _DS.textPrimary,
//                   fontSize: _DS.fontXL,
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'I will remind you to take\n${widget.medicineName}',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   color: _DS.textPrimary,
//                   fontSize: _DS.fontLg,
//                   height: 1.5,
//                 ),
//               ),
//               if (widget.times.isNotEmpty) ...[
//                 const SizedBox(height: 8),
//                 Text(
//                   'At: $_timeSummary',
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     color: _DS.accentBlue,
//                     fontSize: _DS.fontMd,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//               const SizedBox(height: 28),
//               SizedBox(
//                 width: double.infinity,
//                 height: 60,
//                 child: ElevatedButton(
//                   onPressed: widget.onDone,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _DS.successGreen,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(_DS.radiusMd),
//                     ),
//                     textStyle: const TextStyle(
//                       fontSize: _DS.fontLg,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   child: const Text('Great! 👍'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
