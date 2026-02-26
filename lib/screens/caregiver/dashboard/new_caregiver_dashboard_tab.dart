// lib/screens/caregiver/dashboard/new_caregiver_dashboard_tab.dart
//
// ⚠️  DEPRECATED — Unified into caregiver_dashboard_tab.dart
//
// This file is kept ONLY so that any import of NewCaregiverDashboardTab
// in other parts of the codebase still compiles without changes.
// Migrate call sites to CaregiverDashboardTab directly when convenient.
// ─────────────────────────────────────────────────────────────────────────────
import 'caregiver_dashboard_tab.dart';

export 'caregiver_dashboard_tab.dart' show CaregiverDashboardTab;

/// Backward-compat alias.
/// Replace uses of NewCaregiverDashboardTab with CaregiverDashboardTab.
typedef NewCaregiverDashboardTab = CaregiverDashboardTab;
