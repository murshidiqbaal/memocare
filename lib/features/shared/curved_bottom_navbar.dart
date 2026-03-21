// import 'package:flutter/material.dart';

// // ─────────────────────────────────────────────────────────────
// //  Design tokens — kept in sync with patient_dashboard_tab.dart
// // ─────────────────────────────────────────────────────────────
// class _C {
//   static const bg = Color(0xFFFFFFFF);
//   static const lavender = Color(0xFF7C5CBF);
//   static const lavenderSoft = Color(0xFFEDE8F8);
//   static const inkMid = Color(0xFF9B96AA);
//   static const shadow = Color(0xFFD4B8A0);
// }

// // ─────────────────────────────────────────────────────────────
// //  Nav item data
// // ─────────────────────────────────────────────────────────────
// class _NavItem {
//   final IconData icon;
//   final IconData activeIcon;
//   final String label;

//   const _NavItem({
//     required this.icon,
//     required this.activeIcon,
//     required this.label,
//   });
// }

// const _items = [
//   _NavItem(
//     icon: Icons.home_outlined,
//     activeIcon: Icons.home_rounded,
//     label: 'Home',
//   ),
//   _NavItem(
//     icon: Icons.photo_library_outlined,
//     activeIcon: Icons.photo_library_rounded,
//     label: 'Memories',
//   ),
//   _NavItem(
//     icon: Icons.sports_esports_outlined,
//     activeIcon: Icons.sports_esports_rounded,
//     label: 'Games',
//   ),
//   _NavItem(
//     icon: Icons.person_outline_rounded,
//     activeIcon: Icons.person_rounded,
//     label: 'Profile',
//   ),
// ];

// // ─────────────────────────────────────────────────────────────
// //  Curved notch painter
// // ─────────────────────────────────────────────────────────────
// class _CurvedNavPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = _C.bg
//       ..style = PaintingStyle.fill;

//     // Subtle warm shadow at the top edge
//     final shadowPaint = Paint()
//       ..color = _C.shadow.withOpacity(0.18)
//       ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);

//     const r = 28.0; // top corner radius

//     final path = Path()
//       ..moveTo(0, r)
//       ..quadraticBezierTo(0, 0, r, 0)
//       ..lineTo(size.width - r, 0)
//       ..quadraticBezierTo(size.width, 0, size.width, r)
//       ..lineTo(size.width, size.height)
//       ..lineTo(0, size.height)
//       ..close();

//     canvas.drawPath(path, shadowPaint);
//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter _) => false;
// }

// // ─────────────────────────────────────────────────────────────
// //  Public widget
// // ─────────────────────────────────────────────────────────────
// class CurvedBottomNavBar extends StatefulWidget {
//   const CurvedBottomNavBar({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//   });

//   final int currentIndex;
//   final ValueChanged<int> onTap;

//   @override
//   State<CurvedBottomNavBar> createState() => _CurvedBottomNavBarState();
// }

// class _CurvedBottomNavBarState extends State<CurvedBottomNavBar>
//     with TickerProviderStateMixin {
//   // One controller per tab for the scale bounce + indicator slide
//   late List<AnimationController> _tabCtrls;
//   late List<Animation<double>> _scaleAnims;
//   late AnimationController _indicatorCtrl;
//   late Animation<double> _indicatorAnim;
//   int _prevIndex = 0;

//   @override
//   void initState() {
//     super.initState();

//     _tabCtrls = List.generate(
//       _items.length,
//       (_) => AnimationController(
//         vsync: this,
//         duration: const Duration(milliseconds: 260),
//       ),
//     );

//     _scaleAnims = _tabCtrls.map((ctrl) {
//       return TweenSequence<double>([
//         TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.22), weight: 1),
//         TweenSequenceItem(tween: Tween(begin: 1.22, end: 1.0), weight: 1),
//       ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
//     }).toList();

//     _indicatorCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _indicatorAnim = Tween<double>(
//       begin: widget.currentIndex.toDouble(),
//       end: widget.currentIndex.toDouble(),
//     ).animate(
//       CurvedAnimation(parent: _indicatorCtrl, curve: Curves.easeOutCubic),
//     );

//     // Trigger initial active state
//     _tabCtrls[widget.currentIndex].forward();
//   }

//   @override
//   void didUpdateWidget(covariant CurvedBottomNavBar old) {
//     super.didUpdateWidget(old);
//     if (old.currentIndex != widget.currentIndex) {
//       // Bounce the new tab
//       _tabCtrls[widget.currentIndex]
//         ..reset()
//         ..forward();

//       // Slide indicator
//       _indicatorAnim = Tween<double>(
//         begin: _prevIndex.toDouble(),
//         end: widget.currentIndex.toDouble(),
//       ).animate(
//         CurvedAnimation(parent: _indicatorCtrl, curve: Curves.easeOutCubic),
//       );
//       _indicatorCtrl
//         ..reset()
//         ..forward();

//       _prevIndex = widget.currentIndex;
//     }
//   }

//   @override
//   void dispose() {
//     for (final c in _tabCtrls) {
//       c.dispose();
//     }
//     _indicatorCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bottomPad = MediaQuery.of(context).padding.bottom;
//     final barHeight = 70.0 + bottomPad;

//     return SizedBox(
//       height: barHeight,
//       child: CustomPaint(
//         painter: _CurvedNavPainter(),
//         child: Padding(
//           padding: EdgeInsets.only(bottom: bottomPad),
//           child: Stack(
//             children: [
//               // ── Sliding pill indicator ──
//               AnimatedBuilder(
//                 animation: _indicatorAnim,
//                 builder: (_, __) {
//                   return LayoutBuilder(
//                     builder: (context, constraints) {
//                       final itemW = constraints.maxWidth / _items.length;
//                       final pillW = 56.0;
//                       final x =
//                           _indicatorAnim.value * itemW + (itemW - pillW) / 2;
//                       return Positioned(
//                         top: 8,
//                         left: x,
//                         child: Container(
//                           width: pillW,
//                           height: 4,
//                           decoration: BoxDecoration(
//                             color: _C.lavender,
//                             borderRadius: BorderRadius.circular(2),
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),

//               // ── Tab items ──
//               Row(
//                 children: List.generate(_items.length, (i) {
//                   final item = _items[i];
//                   final isActive = widget.currentIndex == i;

//                   return Expanded(
//                     child: GestureDetector(
//                       behavior: HitTestBehavior.opaque,
//                       onTap: () => widget.onTap(i),
//                       child: AnimatedBuilder(
//                         animation: _scaleAnims[i],
//                         builder: (_, child) => Transform.scale(
//                           scale: _scaleAnims[i].value,
//                           child: child,
//                         ),
//                         child: _TabCell(
//                           item: item,
//                           isActive: isActive,
//                         ),
//                       ),
//                     ),
//                   );
//                 }),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────
// //  Individual tab cell
// // ─────────────────────────────────────────────────────────────
// class _TabCell extends StatelessWidget {
//   const _TabCell({required this.item, required this.isActive});

//   final _NavItem item;
//   final bool isActive;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const SizedBox(height: 10),
//         // Icon with animated background bubble
//         AnimatedContainer(
//           duration: const Duration(milliseconds: 220),
//           curve: Curves.easeOut,
//           width: 44,
//           height: 44,
//           decoration: BoxDecoration(
//             color: isActive ? _C.lavenderSoft : Colors.transparent,
//             borderRadius: BorderRadius.circular(14),
//           ),
//           child: Center(
//             child: Icon(
//               isActive ? item.activeIcon : item.icon,
//               size: 24,
//               color: isActive ? _C.lavender : _C.inkMid,
//             ),
//           ),
//         ),
//         const SizedBox(height: 3),
//         // Label
//         AnimatedDefaultTextStyle(
//           duration: const Duration(milliseconds: 200),
//           style: TextStyle(
//             fontSize: 11,
//             fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
//             color: isActive ? _C.lavender : _C.inkMid,
//             letterSpacing: 0.1,
//           ),
//           child: Text(item.label),
//         ),
//       ],
//     );
//   }
// }
