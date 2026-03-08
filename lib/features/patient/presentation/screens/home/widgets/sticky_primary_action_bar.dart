import 'package:flutter/material.dart';

/// Sticky Primary Action Bar - Elder-friendly bottom action button
///
/// Replaces floating action button with a clear, always-visible primary action.
///
/// Design principles:
/// - Full-width for easy targeting
/// - Always visible (no hiding/floating)
/// - Large touch target (64px height)
/// - Strong visual weight
/// - Clear primary action hierarchy
class StickyPrimaryActionBar extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const StickyPrimaryActionBar({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16 * scale,
            offset: Offset(0, -4 * scale),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 20 * scale, vertical: 12 * scale),
          child: SizedBox(
            height: 64 * scale,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? Colors.teal.shade600,
                foregroundColor: foregroundColor ?? Colors.white,
                elevation: 2,
                shadowColor: (backgroundColor ?? Colors.teal).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32 * scale), // Pill shape
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: 28 * scale, vertical: 16 * scale),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 28 * scale),
                  SizedBox(width: 12 * scale),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 20 * scale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
