import 'package:flutter/material.dart';

/// Reusable section title widget for dashboard sections
/// Provides consistent typography and spacing
class SectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;

  const SectionTitle({
    super.key,
    required this.title,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Padding(
      padding: padding ?? EdgeInsets.only(bottom: 12 * scale),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18 * scale,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
