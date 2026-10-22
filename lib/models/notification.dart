import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String targetUserId;
  final String? department;
  final String incidentId;
  final IconData icon;
  final Color color;
  final DateTime createdAt;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.targetUserId,
    required this.incidentId,
    required this.icon,
    required this.color,
    required this.createdAt,
    this.department,
    this.read = false,
  });
}
