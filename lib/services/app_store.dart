import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/notification.dart';
import '../models/responder.dart';
import 'dispatch_engine.dart';
import 'severity_engine.dart';
import 'location_service.dart';

class AppStore extends ChangeNotifier {
  AppStore._();
  static final instance = AppStore._();

  static const Duration responseWindow = Duration(minutes: 2);
  static const double duplicateRadiusKm = 0.15;
  static const Duration duplicateWindow = Duration(minutes: 5);

  UserRole role = UserRole.student;
  AppUser? currentUser;

  final List<Incident> incidents = [];
  final List<AppNotification> notifications = [];
  final Map<String, Timer> _escalationTimers = {};
  final Map<String, Timer> _liveLocationTimers = {};
  Timer? _uiTicker;

  final List<AppUser> users = const [
    AppUser(id: 'STU-001', username: 'student01', password: '1234', name: 'Alex Student', role: UserRole.student),
    AppUser(id: 'STU-002', username: 'student02', password: '1234', name: 'Priya Student', role: UserRole.student),
    AppUser(id: 'STU-003', username: 'student03', password: '1234', name: 'Rahul Student', role: UserRole.student),
    AppUser(id: 'STU-004', username: 'student04', password: '1234', name: 'Ananya Student', role: UserRole.student),
    AppUser(id: 'RES-001', username: 'medical01', password: '1234', name: 'Aarav Medical Team', role: UserRole.responder, department: 'Medical Response', responderId: 'R-101'),
    AppUser(id: 'RES-002', username: 'medical02', password: '1234', name: 'Meera First Aid', role: UserRole.responder, department: 'Medical Response', responderId: 'R-105'),
    AppUser(id: 'RES-003', username: 'security01', password: '1234', name: 'Campus Security Alpha', role: UserRole.responder, department: 'Campus Security', responderId: 'R-102'),
    AppUser(id: 'RES-004', username: 'fire01', password: '1234', name: 'Fire & Rescue Team', role: UserRole.responder, department: 'Fire & Rescue', responderId: 'R-103'),
    AppUser(id: 'RES-005', username: 'fire02', password: '1234', name: 'Fire Response Bravo', role: UserRole.responder, department: 'Fire & Rescue', responderId: 'R-106'),
    AppUser(id: 'RES-006', username: 'security02', password: '1234', name: 'Campus Security Bravo', role: UserRole.responder, department: 'Campus Security', responderId: 'R-107'),
    AppUser(id: 'RES-007', username: 'rapid01', password: '1234', name: 'Rapid Response Beta', role: UserRole.responder, department: 'General Response', responderId: 'R-104'),
    AppUser(id: 'RES-008', username: 'disaster01', password: '1234', name: 'Disaster Response One', role: UserRole.responder, department: 'Disaster Response', responderId: 'R-108'),
    AppUser(id: 'ADM-001', username: 'admin01', password: 'admin123', name: 'Command Officer', role: UserRole.admin),
  ];

  final List<Responder> responders = [
    Responder(id: 'R-101', name: 'Aarav Medical Team', type: 'Medical Response', username: 'medical01', department: 'Medical Response', skills: ['medical', 'first aid', 'rescue'], available: true, latitude: 16.7660, longitude: 80.7574, workload: 0),
    Responder(id: 'R-105', name: 'Meera First Aid', type: 'Medical Response', username: 'medical02', department: 'Medical Response', skills: ['medical', 'first aid'], available: true, latitude: 16.7690, longitude: 80.7580, workload: 0),
    Responder(id: 'R-102', name: 'Campus Security Alpha', type: 'Security Unit', username: 'security01', department: 'Campus Security', skills: ['security', 'patrol'], available: true, latitude: 16.7680, longitude: 80.7600, workload: 0),
    Responder(id: 'R-107', name: 'Campus Security Bravo', type: 'Security Unit', username: 'security02', department: 'Campus Security', skills: ['security', 'patrol', 'rescue'], available: true, latitude: 16.7650, longitude: 80.7550, workload: 0),
    Responder(id: 'R-103', name: 'Fire & Rescue Team', type: 'Fire Response', username: 'fire01', department: 'Fire & Rescue', skills: ['fire', 'rescue', 'disaster'], available: true, latitude: 16.7645, longitude: 80.7565, workload: 0),
    Responder(id: 'R-106', name: 'Fire Response Bravo', type: 'Fire Response', username: 'fire02', department: 'Fire & Rescue', skills: ['fire', 'rescue'], available: true, latitude: 16.7710, longitude: 80.7600, workload: 0),
    Responder(id: 'R-104', name: 'Rapid Response Beta', type: 'General Response', username: 'rapid01', department: 'General Response', skills: ['general', 'rescue'], available: true, latitude: 16.7700, longitude: 80.7540, workload: 0),
    Responder(id: 'R-108', name: 'Disaster Response One', type: 'Disaster Response', username: 'disaster01', department: 'Disaster Response', skills: ['rescue', 'disaster'], available: true, latitude: 16.7620, longitude: 80.7590, workload: 0),
  ];

  String get userName => currentUser?.name ?? 'Guest';
  String get currentUserId => currentUser?.id ?? '';
  Responder? get currentResponder => responderById(currentUser?.responderId);

  List<Incident> get activeIncidents => incidents.where((i) => i.isActive).toList();
  List<Incident> get myIncidents => incidents.where((i) => i.reporterUserIds.contains(currentUserId)).toList();
  List<Incident> get myResponderIncidents => incidents.where((i) => i.responderId == currentUser?.responderId && i.isActive).toList();
  List<AppNotification> get myNotifications {
    final list = notifications.where((n) => n.targetUserId == currentUserId || (currentUser?.role == UserRole.admin && n.targetUserId == 'COMMAND_CENTER')).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
  int get unreadNotificationCount => myNotifications.where((n) => !n.read).length;
  int get criticalCount => activeIncidents.where((i) => i.severity == 'CRITICAL').length;

  bool authenticate(String username, String password) {
    final normalized = username.trim().toLowerCase();
    AppUser? match;
    for (final user in users) {
      if (user.username.toLowerCase() == normalized && user.password == password) {
        match = user;
        break;
      }
    }
    if (match == null) return false;
    currentUser = match;
    role = match.role;
    notifyListeners();
    return true;
  }

  void logout() {
    currentUser = null;
    role = UserRole.student;
    notifyListeners();
  }

  Responder? responderById(String? id) {
    if (id == null) return null;
    for (final r in responders) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<ResponderMatch> rankedResponders(Incident incident) => DispatchEngine.rank(
        incident: incident,
        responders: responders,
        preferredDepartment: incident.department,
      );

  int secondsRemaining(Incident incident) {
    final deadline = incident.responseDeadline;
    if (deadline == null) return 0;
    return deadline.difference(DateTime.now()).inSeconds.clamp(0, 120).toInt();
  }

  void markAllNotificationsRead() {
    for (final n in myNotifications) n.read = true;
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final item = notifications.where((n) => n.id == id).firstOrNull;
    if (item == null) return;
    item.read = true;
    notifyListeners();
  }

  void _notify({
    required String title,
    required String message,
    required String targetUserId,
    required String incidentId,
    String? department,
    IconData icon = Icons.notifications_active_rounded,
    Color color = const Color(0xFF1769FF),
  }) {
    notifications.insert(0, AppNotification(
      id: 'N-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      message: message,
      targetUserId: targetUserId,
      department: department,
      incidentId: incidentId,
      icon: icon,
      color: color,
      createdAt: DateTime.now(),
    ));
  }

  String _departmentFor(IncidentCategory category) => switch (category) {
        IncidentCategory.fire => 'Fire & Rescue',
        IncidentCategory.medical => 'Medical Response',
        IncidentCategory.accident => 'Medical Response',
        IncidentCategory.security => 'Campus Security',
        IncidentCategory.disaster => 'Disaster Response',
        IncidentCategory.other => 'General Response',
      };

  Incident? _findDuplicate({
    required IncidentCategory category,
    required double latitude,
    required double longitude,
    required DateTime now,
  }) {
    for (final existing in incidents.where((i) => i.isActive)) {
      if (now.difference(existing.createdAt).abs() > duplicateWindow) continue;
      final distance = DispatchEngine.distanceKm(latitude, longitude, existing.latitude, existing.longitude);
      if (distance <= duplicateRadiusKm) return existing;
    }
    return null;
  }

  Incident createIncident({
    required IncidentCategory category,
    required String description,
    required int peopleAffected,
    required double latitude,
    required double longitude,
    required String locationLabel,
    String? photoPath,
  }) {
    final now = DateTime.now();
    final duplicate = _findDuplicate(category: category, latitude: latitude, longitude: longitude, now: now);

    if (duplicate != null) {
      if (!duplicate.reporterUserIds.contains(currentUserId)) {
        duplicate.reporterUserIds.add(currentUserId);
        duplicate.isDuplicateReport = true;
        duplicate.timeline.add(TimelineEvent(
          title: 'Duplicate report merged',
          detail: '${userName} reported the same ${category.label.toLowerCase()} incident. Total reports: ${duplicate.reporterCount}.',
          time: now,
        ));
      }
      _notify(
        title: 'Duplicate report detected',
        message: 'A nearby ${category.label.toLowerCase()} emergency is already active as ${duplicate.id}. Your report was linked to the existing incident, so responders are not duplicated.',
        targetUserId: currentUserId,
        incidentId: duplicate.id,
        department: duplicate.department,
        icon: Icons.content_copy_rounded,
        color: Colors.orange,
      );
      _notify(
        title: 'Additional witness report',
        message: '${userName} also reported ${duplicate.id}. ${duplicate.reporterCount} students have now reported this incident.',
        targetUserId: 'COMMAND_CENTER',
        incidentId: duplicate.id,
        department: duplicate.department,
        icon: Icons.groups_rounded,
        color: Colors.orange,
      );
      notifyListeners();
      return duplicate;
    }

    final department = _departmentFor(category);
    final severity = SeverityEngine.evaluate(
      category: category,
      peopleAffected: peopleAffected,
      highRiskLocation: category == IncidentCategory.fire || category == IncidentCategory.disaster,
      isNight: now.hour < 6 || now.hour >= 19,
      description: description,
    );

    final incident = Incident(
      id: 'RG-${1000 + incidents.length + 1}',
      category: category,
      description: description,
      peopleAffected: peopleAffected,
      latitude: latitude,
      longitude: longitude,
      locationLabel: locationLabel,
      photoPath: photoPath,
      severityScore: severity.score,
      severity: severity.level,
      status: IncidentStatus.reported,
      createdAt: now,
      reporterUserId: currentUserId,
      department: department,
    );
    incident.timeline.add(TimelineEvent(title: 'Emergency reported', detail: '${category.label} • GPS captured', time: now));
    incidents.insert(0, incident);

    _notify(
      title: 'Emergency submitted successfully',
      message: '${incident.id} created. ${incident.severity} (${incident.severityScore}/100). Response team is being selected.',
      targetUserId: incident.reporterUserId,
      incidentId: incident.id,
      department: department,
      icon: Icons.check_circle_rounded,
      color: Colors.green,
    );

    _notifyDepartment(incident);
    _assignNextResponder(incident, excludeResponderId: null, reason: 'Automatic smart dispatch');
    _notify(
      title: 'Command center alert',
      message: '${incident.id} routed to $department. ${incident.severity} priority requires monitoring.',
      targetUserId: 'COMMAND_CENTER',
      incidentId: incident.id,
      department: department,
      icon: Icons.support_agent_rounded,
      color: Colors.deepPurple,
    );

    _ensureTicker();
    notifyListeners();
    return incident;
  }

  void _notifyDepartment(Incident incident) {
    for (final user in users.where((u) => u.role == UserRole.responder && (u.department == incident.department || (incident.department == 'Disaster Response' && u.department == 'General Response')))) {
      _notify(
        title: 'NEW ${incident.severity} INCIDENT',
        message: '${incident.category.label} • ${incident.locationLabel}. You are in the responsible department.',
        targetUserId: user.id,
        incidentId: incident.id,
        department: incident.department,
        icon: incident.category.icon,
        color: incident.severityColor,
      );
    }
  }

  void _assignNextResponder(Incident incident, {String? excludeResponderId, required String reason}) {
    final ranked = DispatchEngine.rank(
      incident: incident,
      responders: responders,
      preferredDepartment: incident.department,
      excludeResponderId: excludeResponderId,
    );

    if (ranked.isEmpty) {
      incident.responderId = null;
      incident.status = IncidentStatus.reported;
      incident.assignedAt = null;
      incident.responseDeadline = null;
      incident.timeline.add(TimelineEvent(title: 'Escalated to command center', detail: 'No suitable available responder in ${incident.department}.', time: DateTime.now()));
      _notify(title: 'URGENT: Manual dispatch required', message: '${incident.id} has no available ${incident.department} responder.', targetUserId: 'COMMAND_CENTER', incidentId: incident.id, department: incident.department, icon: Icons.priority_high_rounded, color: Colors.red);
      notifyListeners();
      return;
    }

    final match = ranked.first;
    final responder = match.responder;
    incident.responderId = responder.id;
    incident.status = IncidentStatus.assigned;
    incident.assignedAt = DateTime.now();
    incident.responseDeadline = DateTime.now().add(responseWindow);
    incident.assignmentAttempt++;
    responder.available = false;
    responder.workload++;

    incident.timeline.add(TimelineEvent(title: 'Responder assigned', detail: '#${match.arrivalRank} ${responder.name} • ${match.distanceKm.toStringAsFixed(2)} km • ${match.etaMinutes} min ETA • $reason', time: DateTime.now()));

    final targetUser = users.where((u) => u.responderId == responder.id).firstOrNull;
    if (targetUser != null) {
      _notify(
        title: incident.assignmentAttempt == 1 ? 'YOU ARE THE PRIMARY RESPONDER' : 'ESCALATED — YOU ARE NEXT',
        message: '${incident.category.label} • ${incident.locationLabel} • ${incident.severity}. Accept within 2 minutes. ETA ${match.etaMinutes} min • ${match.distanceKm.toStringAsFixed(2)} km.',
        targetUserId: targetUser.id,
        incidentId: incident.id,
        department: incident.department,
        icon: Icons.emergency_share_rounded,
        color: incident.severityColor,
      );
    }

    _notify(
      title: 'Responder ranked #${match.arrivalRank}',
      message: '${responder.name} selected by fastest estimated arrival: ${match.etaMinutes} min (${match.distanceKm.toStringAsFixed(2)} km).',
      targetUserId: 'COMMAND_CENTER',
      incidentId: incident.id,
      department: incident.department,
      icon: Icons.leaderboard_rounded,
      color: Colors.deepPurple,
    );

    _scheduleEscalation(incident, responder.id);
    _startLiveLocationSimulation(incident, responder);
    notifyListeners();
  }

  void _scheduleEscalation(Incident incident, String responderId) {
    _escalationTimers[incident.id]?.cancel();
    _escalationTimers[incident.id] = Timer(responseWindow, () {
      if (!incident.isActive || incident.status != IncidentStatus.assigned || incident.responderId != responderId) return;
      _escalateUnanswered(incident, responderId);
    });
    _ensureTicker();
  }

  void _ensureTicker() {
    _uiTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (_escalationTimers.isEmpty && !incidents.any((i) => i.responseDeadline != null)) return;
      notifyListeners();
    });
  }

  void _escalateUnanswered(Incident incident, String oldResponderId) {
    final old = responderById(oldResponderId);
    if (old != null) {
      old.available = true;
      old.workload = (old.workload - 1).clamp(0, 99).toInt();
    }
    incident.responseDeadline = null;
    _notify(title: 'Assignment escalated', message: '${old?.name ?? 'Responder'} did not respond within 2 minutes. The incident is being routed to the next responder.', targetUserId: 'COMMAND_CENTER', incidentId: incident.id, department: incident.department, icon: Icons.sync_problem_rounded, color: Colors.orange);
    final oldUser = users.where((u) => u.responderId == oldResponderId).firstOrNull;
    if (oldUser != null) {
      _notify(title: 'Missed 2-minute response window', message: '${incident.id} was escalated because the acceptance window expired.', targetUserId: oldUser.id, incidentId: incident.id, department: incident.department, icon: Icons.timer_off_rounded, color: Colors.orange);
    }
    incident.timeline.add(TimelineEvent(title: 'Assignment escalated', detail: '${old?.name ?? 'Responder'} did not accept within 2 minutes.', time: DateTime.now()));
    _assignNextResponder(incident, excludeResponderId: oldResponderId, reason: 'Previous responder did not respond within 2 minutes');
    notifyListeners();
  }

  void updateStatus(Incident incident, IncidentStatus status) {
    if (incident.status == status) return;
    if (status == IncidentStatus.accepted) {
      _escalationTimers[incident.id]?.cancel();
      incident.responseDeadline = null;
    }
    incident.status = status;
    final responder = responderById(incident.responderId);
    final responderUser = users.where((u) => u.responderId == responder?.id).firstOrNull;

    final detail = switch (status) {
      IncidentStatus.accepted => '${responder?.name ?? 'Responder'} accepted the assignment',
      IncidentStatus.enRoute => 'Responder is travelling to incident • live location active',
      IncidentStatus.arrived => 'Responder reached incident location',
      IncidentStatus.resolved => 'Incident closed successfully',
      IncidentStatus.reported => 'Incident created',
      IncidentStatus.assigned => 'Responder assigned',
    };

    incident.timeline.add(TimelineEvent(title: status.label, detail: detail, time: DateTime.now()));
    _notify(title: 'Incident ${status.label}', message: '${incident.id} • ${incident.category.label} • ${incident.locationLabel}', targetUserId: incident.reporterUserId, incidentId: incident.id, department: incident.department, icon: Icons.update_rounded, color: status.color);
    for (final reporterId in incident.reporterUserIds.where((id) => id != incident.reporterUserId)) {
      _notify(title: 'Linked incident ${status.label}', message: '${incident.id} has changed to ${status.label}.', targetUserId: reporterId, incidentId: incident.id, department: incident.department, icon: Icons.update_rounded, color: status.color);
    }
    _notify(title: '${incident.id} — ${status.label}', message: detail, targetUserId: 'COMMAND_CENTER', incidentId: incident.id, department: incident.department, icon: Icons.monitor_heart_rounded, color: status.color);
    if (responderUser != null) {
      _notify(title: 'Status recorded', message: '${incident.id} is now ${status.label}.', targetUserId: responderUser.id, incidentId: incident.id, department: incident.department, icon: Icons.check_circle_rounded, color: status.color);
    }

    if (status == IncidentStatus.resolved && responder != null) {
      responder.available = true;
      responder.workload = (responder.workload - 1).clamp(0, 99).toInt();
      _liveLocationTimers[incident.id]?.cancel();
      _liveLocationTimers.remove(incident.id);
      incident.responseDeadline = null;
    }
    notifyListeners();
  }

  void declineAssignment(Incident incident) {
    _escalationTimers[incident.id]?.cancel();
    final currentId = incident.responderId;
    final current = responderById(currentId);
    if (current != null) {
      current.available = true;
      current.workload = (current.workload - 1).clamp(0, 99).toInt();
    }
    incident.responseDeadline = null;
    _notify(title: 'Assignment declined', message: '${current?.name ?? 'Responder'} declined ${incident.id}. Searching next responder.', targetUserId: 'COMMAND_CENTER', incidentId: incident.id, department: incident.department, icon: Icons.person_off_rounded, color: Colors.orange);
    final currentUser = users.where((u) => u.responderId == currentId).firstOrNull;
    if (currentUser != null) {
      _notify(title: 'Assignment declined', message: 'You declined ${incident.id}. RescueGrid is immediately searching for the next responder.', targetUserId: currentUser.id, incidentId: incident.id, department: incident.department, icon: Icons.alt_route_rounded, color: Colors.orange);
    }
    incident.timeline.add(TimelineEvent(title: 'Responder declined', detail: current?.name ?? 'Responder', time: DateTime.now()));
    _assignNextResponder(incident, excludeResponderId: currentId, reason: 'Previous responder declined');
    notifyListeners();
  }

  void setResponderAvailability(bool available) {
    final responder = currentResponder;
    if (responder == null) return;
    if (!available && responder.workload > 0) return;
    responder.available = available;
    _notify(title: available ? 'Responder available' : 'Responder paused', message: '${responder.name} is ${available ? 'available for dispatch' : 'temporarily unavailable'}.', targetUserId: 'COMMAND_CENTER', incidentId: 'SYSTEM', department: responder.department, icon: available ? Icons.check_circle_rounded : Icons.pause_circle_rounded, color: available ? Colors.green : Colors.grey);
    notifyListeners();
  }

  void _startLiveLocationSimulation(Incident incident, Responder responder) {
    _liveLocationTimers[incident.id]?.cancel();
    _liveLocationTimers[incident.id] = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!incident.isActive || incident.status == IncidentStatus.resolved) {
        _liveLocationTimers[incident.id]?.cancel();
        _liveLocationTimers.remove(incident.id);
        return;
      }

      // Use real device GPS when available. If the contest emulator/desktop has no
      // GPS signal, fall back to a smooth demo movement so the live map still works.
      final position = await CampusLocation.getCurrentPosition();
      if (position != null) {
        responder.latitude = position.latitude;
        responder.longitude = position.longitude;
      } else {
        final latStep = (incident.latitude - responder.latitude) * .08;
        final lonStep = (incident.longitude - responder.longitude) * .08;
        responder.latitude += latStep;
        responder.longitude += lonStep;
      }
      notifyListeners();
    });
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
