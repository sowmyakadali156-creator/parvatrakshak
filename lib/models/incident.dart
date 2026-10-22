import 'package:flutter/material.dart';

enum IncidentStatus { reported, assigned, accepted, enRoute, arrived, resolved }

enum IncidentCategory { fire, medical, accident, security, disaster, other }

extension IncidentCategoryX on IncidentCategory {
  String get label => switch (this) {
        IncidentCategory.fire => 'Fire',
        IncidentCategory.medical => 'Medical',
        IncidentCategory.accident => 'Accident',
        IncidentCategory.security => 'Security',
        IncidentCategory.disaster => 'Disaster',
        IncidentCategory.other => 'Other',
      };

  IconData get icon => switch (this) {
        IncidentCategory.fire => Icons.local_fire_department_rounded,
        IncidentCategory.medical => Icons.medical_services_rounded,
        IncidentCategory.accident => Icons.car_crash_rounded,
        IncidentCategory.security => Icons.shield_rounded,
        IncidentCategory.disaster => Icons.flood_rounded,
        IncidentCategory.other => Icons.warning_amber_rounded,
      };
}

extension IncidentStatusX on IncidentStatus {
  String get label => switch (this) {
        IncidentStatus.reported => 'Reported',
        IncidentStatus.assigned => 'Assigned',
        IncidentStatus.accepted => 'Accepted',
        IncidentStatus.enRoute => 'En Route',
        IncidentStatus.arrived => 'Arrived',
        IncidentStatus.resolved => 'Resolved',
      };

  Color get color => switch (this) {
        IncidentStatus.reported => Colors.blue,
        IncidentStatus.assigned => Colors.deepPurple,
        IncidentStatus.accepted => Colors.teal,
        IncidentStatus.enRoute => Colors.orange,
        IncidentStatus.arrived => Colors.indigo,
        IncidentStatus.resolved => Colors.green,
      };
}

class TimelineEvent {
  final String title;
  final String detail;
  final DateTime time;

  TimelineEvent({required this.title, required this.detail, required this.time});
}

class Incident {
  final String id;
  final IncidentCategory category;
  final String description;
  final int peopleAffected;
  final double latitude;
  final double longitude;
  final String locationLabel;
  final String? photoPath;
  final int severityScore;
  final String severity;
  IncidentStatus status;
  String? responderId;
  final String reporterUserId;
  final List<String> reporterUserIds;
  final String department;
  DateTime? assignedAt;
  DateTime? responseDeadline;
  int assignmentAttempt;
  final DateTime createdAt;
  final List<TimelineEvent> timeline;
  bool isDuplicateReport;

  Incident({
    required this.id,
    required this.category,
    required this.description,
    required this.peopleAffected,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
    this.photoPath,
    required this.severityScore,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.responderId,
    required this.reporterUserId,
    List<String>? reporterUserIds,
    required this.department,
    this.assignedAt,
    this.responseDeadline,
    this.assignmentAttempt = 0,
    List<TimelineEvent>? timeline,
    this.isDuplicateReport = false,
  })  : reporterUserIds = reporterUserIds ?? [reporterUserId],
        timeline = timeline ?? [];

  bool get isActive => status != IncidentStatus.resolved;
  int get reporterCount => reporterUserIds.length;

  Color get severityColor {
    if (severity == 'CRITICAL') return const Color(0xFFE53935);
    if (severity == 'HIGH') return const Color(0xFFFF7A00);
    if (severity == 'MEDIUM') return const Color(0xFFFFB300);
    return const Color(0xFF18A558);
  }
}
