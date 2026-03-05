// // ============================================================
// // MemoCare Admin - Data Models
// // lib/features/admin/models/
// // ============================================================

// // ─── models/admin_user.dart ─────────────────────────────────

// import 'package:freezed_annotation/freezed_annotation.dart';

// part 'admin_user.freezed.dart';
// part 'admin_user.g.dart';

// /// Represents a platform user (patient, caregiver, or admin)
// @freezed
// class AdminUser with _$AdminUser {
//   const factory AdminUser({
//     required String id,
//     required String fullName,
//     String? phone,
//     String? avatarUrl,
//     required String role, // 'patient' | 'caregiver' | 'admin'
//     DateTime? dateOfBirth,
//     String? address,
//     String? emergencyContact,
//     required DateTime createdAt,
//     required DateTime updatedAt,
//     required bool isActive,
//   }) = _AdminUser;

//   factory AdminUser.fromJson(Map<String, dynamic> json) =>
//       _$AdminUserFromJson(json);
// }

// // ─── models/caregiver_verification.dart ─────────────────────

// /// Caregiver verification record
// @freezed
// class CaregiverVerification with _$CaregiverVerification {
//   const factory CaregiverVerification({
//     required String id,
//     required String caregiverId,
//     required bool verified,
//     required String verificationStatus, // pending|verified|rejected|suspended
//     String? verifiedBy,
//     DateTime? verifiedAt,
//     String? rejectionReason,
//     String? idDocumentUrl,
//     String? certificateUrl,
//     String? notes,
//     required DateTime createdAt,
//     required DateTime updatedAt,
//     // Joined caregiver profile
//     AdminUser? caregiver,
//   }) = _CaregiverVerification;

//   factory CaregiverVerification.fromJson(Map<String, dynamic> json) =>
//       _$CaregiverVerificationFromJson(json);
// }

// // ─── models/patient_safety_alert.dart ───────────────────────

// /// Centralized patient safety alert
// @freezed
// class PatientSafetyAlert with _$PatientSafetyAlert {
//   const factory PatientSafetyAlert({
//     required String id,
//     required String patientId,
//     required String alertType,
//     required String severity, // low|medium|high|critical
//     required String message,
//     String? sourceTable,
//     String? sourceId,
//     required bool resolved,
//     String? resolvedBy,
//     DateTime? resolvedAt,
//     required DateTime createdAt,
//     // Joined
//     AdminUser? patient,
//   }) = _PatientSafetyAlert;

//   factory PatientSafetyAlert.fromJson(Map<String, dynamic> json) =>
//       _$PatientSafetyAlertFromJson(json);
// }

// // ─── models/audit_log.dart ───────────────────────────────────

// /// Immutable audit trail entry
// @freezed
// class AuditLog with _$AuditLog {
//   const factory AuditLog({
//     required String id,
//     String? actorId,
//     String? actorRole,
//     required String actionType,
//     String? targetTable,
//     String? targetId,
//     Map<String, dynamic>? oldValue,
//     Map<String, dynamic>? newValue,
//     String? ipAddress,
//     String? deviceInfo,
//     required DateTime createdAt,
//     // Joined
//     AdminUser? actor,
//   }) = _AuditLog;

//   factory AuditLog.fromJson(Map<String, dynamic> json) =>
//       _$AuditLogFromJson(json);
// }

// // ─── models/moderation_item.dart ────────────────────────────

// /// Item in the moderation review queue
// @freezed
// class ModerationItem with _$ModerationItem {
//   const factory ModerationItem({
//     required String id,
//     required String itemType, // caregiver|memory_image|notification|game_data
//     required String itemId,
//     required String reason,
//     String? reportedBy,
//     required String status, // pending|approved|rejected
//     String? reviewedBy,
//     DateTime? reviewedAt,
//     String? adminNotes,
//     required DateTime createdAt,
//     // Joined
//     AdminUser? reporter,
//   }) = _ModerationItem;

//   factory ModerationItem.fromJson(Map<String, dynamic> json) =>
//       _$ModerationItemFromJson(json);
// }

// // ─── models/ai_risk_flag.dart ────────────────────────────────

// /// AI-detected risk flag for a patient
// @freezed
// class AiRiskFlag with _$AiRiskFlag {
//   const factory AiRiskFlag({
//     required String id,
//     required String patientId,
//     required String riskType,
//     required double riskScore, // 0-100
//     required String description,
//     required bool reviewed,
//     String? reviewedBy,
//     DateTime? reviewedAt,
//     required DateTime createdAt,
//     // Joined
//     AdminUser? patient,
//   }) = _AiRiskFlag;

//   factory AiRiskFlag.fromJson(Map<String, dynamic> json) =>
//       _$AiRiskFlagFromJson(json);
// }

// // ─── models/admin_stats.dart ─────────────────────────────────

// /// Aggregated stats for the dashboard
// class AdminStats {
//   final int totalPatients;
//   final int totalCaregivers;
//   final int verifiedCaregivers;
//   final int activeSafetyAlerts;
//   final int activeSos;
//   final int locationBreaches;
//   final int gameActivityToday;
//   final int pendingModeration;
//   final int highRiskPatients;

//   const AdminStats({
//     required this.totalPatients,
//     required this.totalCaregivers,
//     required this.verifiedCaregivers,
//     required this.activeSafetyAlerts,
//     required this.activeSos,
//     required this.locationBreaches,
//     required this.gameActivityToday,
//     required this.pendingModeration,
//     required this.highRiskPatients,
//   });

//   factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
//         totalPatients: (json['total_patients'] as num?)?.toInt() ?? 0,
//         totalCaregivers: (json['total_caregivers'] as num?)?.toInt() ?? 0,
//         verifiedCaregivers: (json['verified_caregivers'] as num?)?.toInt() ?? 0,
//         activeSafetyAlerts:
//             (json['active_safety_alerts'] as num?)?.toInt() ?? 0,
//         activeSos: (json['active_sos'] as num?)?.toInt() ?? 0,
//         locationBreaches: (json['location_breaches'] as num?)?.toInt() ?? 0,
//         gameActivityToday: (json['game_activity_today'] as num?)?.toInt() ?? 0,
//         pendingModeration: (json['pending_moderation'] as num?)?.toInt() ?? 0,
//         highRiskPatients: (json['high_risk_patients'] as num?)?.toInt() ?? 0,
//       );

//   AdminStats copyWith({
//     int? totalPatients,
//     int? totalCaregivers,
//     int? verifiedCaregivers,
//     int? activeSafetyAlerts,
//     int? activeSos,
//     int? locationBreaches,
//     int? gameActivityToday,
//     int? pendingModeration,
//     int? highRiskPatients,
//   }) =>
//       AdminStats(
//         totalPatients: totalPatients ?? this.totalPatients,
//         totalCaregivers: totalCaregivers ?? this.totalCaregivers,
//         verifiedCaregivers: verifiedCaregivers ?? this.verifiedCaregivers,
//         activeSafetyAlerts: activeSafetyAlerts ?? this.activeSafetyAlerts,
//         activeSos: activeSos ?? this.activeSos,
//         locationBreaches: locationBreaches ?? this.locationBreaches,
//         gameActivityToday: gameActivityToday ?? this.gameActivityToday,
//         pendingModeration: pendingModeration ?? this.pendingModeration,
//         highRiskPatients: highRiskPatients ?? this.highRiskPatients,
//       );
// }

// // ─── models/compliance_point.dart ───────────────────────────

// /// Single data point for reminder compliance chart
// class CompliancePoint {
//   final DateTime day;
//   final int total;
//   final int acknowledged;
//   final double rate;

//   const CompliancePoint({
//     required this.day,
//     required this.total,
//     required this.acknowledged,
//     required this.rate,
//   });

//   factory CompliancePoint.fromJson(Map<String, dynamic> json) =>
//       CompliancePoint(
//         day: DateTime.parse(json['day'] as String),
//         total: (json['total_reminders'] as num).toInt(),
//         acknowledged: (json['acknowledged_count'] as num).toInt(),
//         rate: (json['compliance_rate'] as num?)?.toDouble() ?? 0.0,
//       );
// }

// // ─── models/notification_log.dart ───────────────────────────

// /// Push notification delivery record
// @freezed
// class NotificationLog with _$NotificationLog {
//   const factory NotificationLog({
//     required String id,
//     required String recipientId,
//     required String title,
//     required String body,
//     required String notificationType,
//     required bool delivered,
//     String? deliveryError,
//     required DateTime sentAt,
//     DateTime? openedAt,
//     AdminUser? recipient,
//   }) = _NotificationLog;

//   factory NotificationLog.fromJson(Map<String, dynamic> json) =>
//       _$NotificationLogFromJson(json);
// }

// // ─── models/admin_role_model.dart ────────────────────────────

// /// Admin permission model
// @freezed
// class AdminRoleModel with _$AdminRoleModel {
//   const factory AdminRoleModel({
//     required String id,
//     required String adminId,
//     required String role,
//     required bool canVerifyCaregiver,
//     required bool canDeleteMemory,
//     required bool canViewLocation,
//     required bool canResolveAlert,
//     required bool canManageUsers,
//     required bool canViewAuditLogs,
//     required DateTime createdAt,
//   }) = _AdminRoleModel;

//   factory AdminRoleModel.fromJson(Map<String, dynamic> json) =>
//       _$AdminRoleModelFromJson(json);
// }

// // ─── models/game_analytics.dart ─────────────────────────────

// /// Aggregated game analytics per patient
// class GameAnalytics {
//   final String patientId;
//   final String patientName;
//   final int totalSessions;
//   final double avgScore;
//   final double avgDurationSec;
//   final DateTime? lastPlayed;

//   const GameAnalytics({
//     required this.patientId,
//     required this.patientName,
//     required this.totalSessions,
//     required this.avgScore,
//     required this.avgDurationSec,
//     this.lastPlayed,
//   });

//   factory GameAnalytics.fromJson(Map<String, dynamic> json) => GameAnalytics(
//         patientId: json['patient_id'] as String,
//         patientName: json['patient_name'] as String? ?? 'Unknown',
//         totalSessions: (json['total_sessions'] as num).toInt(),
//         avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0.0,
//         avgDurationSec: (json['avg_duration'] as num?)?.toDouble() ?? 0.0,
//         lastPlayed: json['last_played'] != null
//             ? DateTime.parse(json['last_played'] as String)
//             : null,
//       );
// }
