import 'package:flutter/material.dart';

import '../../models/incident.dart';
import '../../services/app_store.dart';
import '../../services/dispatch_engine.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common_widgets.dart';
import 'active_incident.dart';

class ResponderHome extends StatelessWidget {
  const ResponderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        return AppShell(
          role: AppStore.instance.role,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon:
                  Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon:
                  Icon(Icons.assignment_rounded),
              label: 'Assignments',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline_rounded,
              ),
              selectedIcon:
                  Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
          pages: const [
            _ResponderDashboard(),
            _ResponderIncidents(),
            _ResponderProfile(),
          ],
        );
      },
    );
  }
}

class _ResponderDashboard extends StatelessWidget {
  const _ResponderDashboard();

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final responder = store.currentResponder;

    final assignments =
        store.myResponderIncidents;

    final incident =
        assignments.isEmpty ? null : assignments.first;

    final distance =
        incident == null || responder == null
            ? null
            : DispatchEngine.distanceKm(
                incident.latitude,
                incident.longitude,
                responder.latitude,
                responder.longitude,
              );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        30,
      ),
      children: [
        GradientHeader(
          eyebrow:
              responder?.department ??
              'Field response',
          title: 'Respond fast. Stay visible.',
          subtitle:
              'Your dashboard shows only incidents assigned to you. Location and response progress are updated live.',
          icon: Icons.local_shipping_rounded,
        ),

        const SizedBox(height: 16),

        _AvailabilityCard(
          available: responder?.available ?? false,
          onChanged:
              store.setResponderAvailability,
        ),

        const SizedBox(height: 16),

        if (incident != null) ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your active assignment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusDot(
                status: incident.status,
              ),
            ],
          ),

          const SizedBox(height: 10),

          _AssignmentHero(
            incident: incident,
            responder: responder,
            distance: distance,
          ),

          const SizedBox(height: 12),

          if (incident.status ==
                  IncidentStatus.assigned &&
              incident.responseDeadline != null)
            _CountdownBanner(
              seconds:
                  store.secondsRemaining(incident),
            ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Distance',
                  value: distance == null
                      ? '--'
                      : '${distance.toStringAsFixed(2)} km',
                  icon:
                      Icons.social_distance_rounded,
                  color: AppTheme.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'ETA',
                  value: distance == null
                      ? '--'
                      : '${(distance * 3.5).ceil()} min',
                  icon: Icons.timer_rounded,
                  color: AppTheme.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ActiveIncident(
                      incident: incident,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.route_rounded,
              ),
              label: const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 14,
                ),
                child: Text(
                  'OPEN LIVE RESPONSE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ] else
          const EmptyState(
            icon:
                Icons.check_circle_outline_rounded,
            title: 'No active assignment',
            subtitle:
                'You are available for dispatch. A department-matched emergency will appear here.',
          ),

        const SizedBox(height: 20),

        const Text(
          'Your response stats',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Current load',
                value:
                    '${responder?.workload ?? 0}',
                icon: Icons.layers_rounded,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Status',
                value:
                    responder?.available == true
                        ? 'AVAILABLE'
                        : 'BUSY',
                icon:
                    responder?.available == true
                        ? Icons
                            .radio_button_checked_rounded
                        : Icons.pause_circle_rounded,
                color:
                    responder?.available == true
                        ? AppTheme.green
                        : AppTheme.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AssignmentHero extends StatelessWidget {
  final Incident incident;
  final dynamic responder;
  final double? distance;

  const _AssignmentHero({
    required this.incident,
    required this.responder,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final eta = distance == null
        ? '--'
        : '${(distance! * 3.5).ceil()} min';

    return Card(
      color: incident.severityColor
          .withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: incident.severityColor
                    .withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(17),
              ),
              child: Icon(
                incident.category.icon,
                color: incident.severityColor,
                size: 30,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          incident.category.label,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SeverityBadge(
                        severity:
                            incident.severity,
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    incident.locationLabel,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    '${distance?.toStringAsFixed(2) ?? '--'} km away • $eta estimated arrival',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownBanner extends StatelessWidget {
  final int seconds;

  const _CountdownBanner({
    required this.seconds,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    final color = seconds <= 20
        ? AppTheme.red
        : AppTheme.orange;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Accept this assignment before the 2-minute response window expires.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$minutes:${secs.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final IncidentStatus status;

  const _StatusDot({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color:
            status.color.withValues(alpha: 0.1),
        borderRadius:
            BorderRadius.circular(30),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          color: status.color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final bool available;
  final ValueChanged<bool> onChanged;

  const _AvailabilityCard({
    required this.available,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = available
        ? AppTheme.green
        : AppTheme.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color:
                    color.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                available
                    ? Icons
                        .radio_button_checked
                    : Icons.pause_circle,
                color: color,
              ),
            ),

            const SizedBox(width: 12),

            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duty availability',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Only available responders are considered for new assignments.',
                  ),
                ],
              ),
            ),

            Switch(
              value: available,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponderIncidents extends StatelessWidget {
  const _ResponderIncidents();

  @override
  Widget build(BuildContext context) {
    final incidents =
        AppStore.instance.myResponderIncidents;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        30,
      ),
      children: [
        const Text(
          'My assignments',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Only incidents assigned to your responder account are shown here.',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 18),

        if (incidents.isEmpty)
          const EmptyState(
            icon: Icons.inbox_rounded,
            title: 'No assignments',
            subtitle:
                'New department-matched incidents will appear here automatically.',
          )
        else
          ...incidents.map(
            (incident) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: IncidentCard(
                incident: incident,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ActiveIncident(
                        incident: incident,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ResponderProfile extends StatelessWidget {
  const _ResponderProfile();

  @override
  Widget build(BuildContext context) {
    final responder =
        AppStore.instance.currentResponder;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Responder profile',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 18),

        Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.all(18),
            leading: const CircleAvatar(
              radius: 30,
              backgroundColor:
                  Color(0xFFE8F0FF),
              child: Icon(
                Icons.badge_rounded,
                color: AppTheme.blue,
                size: 30,
              ),
            ),
            title: Text(
              AppStore.instance.userName,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              '${responder?.department ?? ''} • ${responder?.type ?? ''}',
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.workspace_premium_rounded,
                ),
                title:
                    const Text('Skills'),
                subtitle: Text(
                  responder?.skills.join(' • ') ??
                      'No skills',
                ),
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(
                  Icons.my_location_rounded,
                ),
                title: const Text(
                  'Live location',
                ),
                subtitle: Text(
                  responder == null
                      ? 'Unavailable'
                      : '${responder.latitude.toStringAsFixed(5)}, '
                          '${responder.longitude.toStringAsFixed(5)}',
                ),
              ),

              const Divider(height: 1),

              const ListTile(
                leading: Icon(
                  Icons.leaderboard_rounded,
                ),
                title: Text(
                  'Dispatch ranking',
                ),
                subtitle: Text(
                  'Ranking is based primarily on estimated arrival time, followed by skill and workload.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}