import 'package:flutter/material.dart';

/// Provides consistent vertical spacing between dashboard sections
/// Ensures proper visual rhythm and hierarchy
class DashboardSpacing {
  // Spacing between section title and content
  static const double titleToContent = 12.0;

  // Spacing between sections
  static const double betweenSections = 28.0;

  // Spacing at the bottom for safe area
  static const double bottomPadding = 80.0;

  // Horizontal padding for content
  static const double horizontalPadding = 20.0;

  // Top padding for content
  static const double topPadding = 16.0;
}

/// Reusable spacing widget
class SectionSpacing extends StatelessWidget {
  final double? height;

  const SectionSpacing({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height ?? DashboardSpacing.betweenSections);
  }
}
