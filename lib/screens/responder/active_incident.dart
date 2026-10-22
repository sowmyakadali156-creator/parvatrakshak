import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/incident.dart';
import '../../services/app_store.dart';
import '../../services/dispatch_engine.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ActiveIncident extends StatelessWidget {
  final Incident incident;

  const ActiveIncident({
    super.key,
    required this.incident,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final store = AppStore.instance;

        final responder =
            store.responderById(
          incident.responderId,
        );

        final assignedToMe =
            store.currentUser?.responderId ==
                incident.responderId;

        final command =
            store.role.name == 'admin';

        final ranking = DispatchEngine.rank(
          incident: incident,
          responders: store.responders,
          preferredDepartment:
              incident.department,
          includeUnavailable: true,
        );

        final liveDistance =
            responder == null
                ? null
                : DispatchEngine.distanceKm(
                    incident.latitude,
                    incident.longitude,
                    responder.latitude,
                    responder.longitude,
                  );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Incident ${incident.id}',
            ),
            actions: [
              Padding(
                padding:
                    const EdgeInsets.only(
                  right: 16,
                ),
                child: SeverityBadge(
                  severity:
                      incident.severity,
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder:
                (context, constraints) {
              final wide =
                  constraints.maxWidth >=
                      1000;

              final map = _buildMap(
                incident,
                responder,
                liveDistance,
              );

              final details =
                  _buildDetails(
                context,
                responder,
                assignedToMe,
                command,
                ranking,
                liveDistance,
              );

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  32,
                ),
                child: wide
                    ? Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: map,
                          ),
                          const SizedBox(
                            width: 18,
                          ),
                          Expanded(
                            flex: 4,
                            child: details,
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          map,
                          const SizedBox(
                            height: 18,
                          ),
                          details,
                        ],
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMap(
    Incident incident,
    dynamic responder,
    double? liveDistance,
  ) {
    final incidentPoint = LatLng(
      incident.latitude,
      incident.longitude,
    );

    final responderPoint = responder == null
        ? null
        : LatLng(
            responder.latitude,
            responder.longitude,
          );

    return Card(
      clipBehavior:
          Clip.antiAlias,
      child: SizedBox(
        height: 470,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter:
                    incidentPoint,
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.rescuegrid.app',
                ),

                if (responderPoint != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          responderPoint,
                          incidentPoint,
                        ],
                        strokeWidth: 6,
                        color:
                            AppTheme.blue,
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point:
                          incidentPoint,
                      width: 55,
                      height: 55,
                      child: const Icon(
                        Icons
                            .location_on_rounded,
                        color:
                            AppTheme.red,
                        size: 48,
                      ),
                    ),

                    if (responderPoint !=
                        null)
                      Marker(
                        point:
                            responderPoint,
                        width: 55,
                        height: 55,
                        child: const Icon(
                          Icons
                              .local_shipping_rounded,
                          color:
                              AppTheme.blue,
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MapPill(
                    icon: Icons
                        .location_on_rounded,
                    text:
                        incident.locationLabel,
                  ),

                  if (liveDistance !=
                      null)
                    _MapPill(
                      icon: Icons
                          .social_distance_rounded,
                      text:
                          '${liveDistance.toStringAsFixed(2)} km live distance',
                    ),

                  if (responder != null)
                    const _LivePill(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    dynamic responder,
    bool assignedToMe,
    bool command,
    List<ResponderMatch> ranking,
    double? liveDistance,
  ) {
    final store =
        AppStore.instance;

    return Column(
      children: [
        Card(
          child: Padding(
            padding:
                const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          incident.severityColor
                              .withValues(
                        alpha: 0.10,
                      ),
                      child: Icon(
                        incident.category.icon,
                        color:
                            incident.severityColor,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            incident.category.label,
                            style:
                                const TextStyle(
                              fontSize: 21,
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                          Text(
                            incident.department,
                            style: TextStyle(
                              color: Colors
                                  .grey
                                  .shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SeverityBadge(
                      severity:
                          incident.severity,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 16,
                ),

                _DetailRow(
                  icon: Icons
                      .priority_high_rounded,
                  label: 'Severity',
                  value:
                      '${incident.severity} • ${incident.severityScore}/100',
                ),

                _DetailRow(
                  icon:
                      Icons.groups_rounded,
                  label: 'Reports',
                  value:
                      '${incident.reporterCount} student report${incident.reporterCount == 1 ? '' : 's'} merged',
                ),

                _DetailRow(
                  icon:
                      Icons.person_rounded,
                  label: 'Assigned',
                  value:
                      responder?.name ??
                          'Unassigned',
                ),

                if (liveDistance !=
                    null)
                  _DetailRow(
                    icon: Icons
                        .near_me_rounded,
                    label:
                        'Live distance',
                    value:
                        '${liveDistance.toStringAsFixed(2)} km',
                  ),

                if (responder != null)
                  _DetailRow(
                    icon: Icons
                        .timer_rounded,
                    label: 'ETA',
                    value:
                        '${_etaFromDistance(liveDistance ?? 0)} min',
                  ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  incident.description,
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (incident.status ==
                IncidentStatus.assigned &&
            incident.responseDeadline !=
                null) ...[
          const SizedBox(height: 12),
          _CountdownCard(
            seconds:
                store.secondsRemaining(
              incident,
            ),
          ),
        ],

        if (assignedToMe) ...[
          const SizedBox(height: 12),
          _ResponderActions(
            incident: incident,
          ),
        ],

        if (command) ...[
          const SizedBox(height: 12),
          Card(
            color:
                const Color(0xFFF5F3FF),
            child: Padding(
              padding:
                  const EdgeInsets.all(17),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      incident.isActive
                          ? () => store
                              .declineAssignment(
                                incident,
                              )
                          : null,
                  icon: const Icon(
                    Icons
                        .alt_route_rounded,
                  ),
                  label: const Text(
                    'Escalate / Reassign Now',
                  ),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),

        _RankingCard(
          ranking: ranking,
          assignedResponderId:
              incident.responderId,
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding:
                const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Response timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                StatusTimeline(
                  incident: incident,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _etaFromDistance(
    double distance,
  ) {
    if (distance <= 0) {
      return 0;
    }

    return (distance * 3.5)
        .ceil()
        .clamp(1, 99)
        .toInt();
  }
}

class _ResponderActions
    extends StatelessWidget {
  final Incident incident;

  const _ResponderActions({
    required this.incident,
  });

  @override
  Widget build(BuildContext context) {
    final store =
        AppStore.instance;

    final next =
        switch (incident.status) {
      IncidentStatus.assigned => (
          IncidentStatus.accepted,
          'ACCEPT ASSIGNMENT',
          Icons.check_rounded,
          AppTheme.green,
        ),
      IncidentStatus.accepted => (
          IncidentStatus.enRoute,
          'START EN ROUTE',
          Icons.navigation_rounded,
          AppTheme.blue,
        ),
      IncidentStatus.enRoute => (
          IncidentStatus.arrived,
          'MARK ARRIVED',
          Icons.location_on_rounded,
          AppTheme.orange,
        ),
      IncidentStatus.arrived => (
          IncidentStatus.resolved,
          'RESOLVE INCIDENT',
          Icons.task_alt_rounded,
          AppTheme.green,
        ),
      _ => null,
    };

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(17),
        child: Column(
          children: [
            if (next != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    store.updateStatus(
                      incident,
                      next.$1,
                    );
                  },
                  icon: Icon(next.$3),
                  label: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: Text(
                      next.$2,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        next.$4,
                  ),
                ),
              ),

            if (incident.status ==
                IncidentStatus.assigned) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  store.declineAssignment(
                    incident,
                  );
                },
                icon: const Icon(
                  Icons.close_rounded,
                ),
                label: const Text(
                  'Decline & immediately reassign',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountdownCard
    extends StatelessWidget {
  final int seconds;

  const _CountdownCard({
    required this.seconds,
  });

  @override
  Widget build(BuildContext context) {
    final minutes =
        seconds ~/ 60;
    final secs =
        seconds % 60;

    final color = seconds <= 20
        ? AppTheme.red
        : AppTheme.orange;

    return Card(
      color:
          color.withValues(alpha: 0.07),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.timer_rounded,
              color: color,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Response window',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$minutes:${secs.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingCard
    extends StatelessWidget {
  final List<ResponderMatch> ranking;
  final String? assignedResponderId;

  const _RankingCard({
    required this.ranking,
    required this.assignedResponderId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.leaderboard_rounded,
                  color: AppTheme.blue,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Responder ranking by arrival time',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Text(
              'Fastest estimated arrival is ranked first. Skill and workload break ties.',
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 12),

            ...ranking.take(4).map(
              (match) {
                final isAssigned =
                    match.responder.id ==
                        assignedResponderId;

                final isFirst =
                    match.arrivalRank == 1;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.all(
                      12,
                    ),
                    decoration:
                        BoxDecoration(
                      color: isAssigned
                          ? AppTheme.blue
                              .withValues(
                              alpha: 0.08,
                            )
                          : const Color(
                              0xFFF6F8FB,
                            ),
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              isFirst
                                  ? AppTheme
                                      .orange
                                      .withValues(
                                      alpha:
                                          0.15,
                                    )
                                  : Colors.white,
                          child: Text(
                            '#${match.arrivalRank}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight
                                      .w900,
                              color: isFirst
                                  ? AppTheme
                                      .orange
                                  : AppTheme
                                      .navy,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                match.responder.name,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                              Text(
                                '${match.distanceKm.toStringAsFixed(2)} km • '
                                '${match.etaMinutes} min ETA • '
                                'Skill ${match.skillScore}%',
                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey
                                      .shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isAssigned)
                          const Icon(
                            Icons
                                .check_circle_rounded,
                            color:
                                AppTheme.green,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.my_location_rounded,
            color: AppTheme.green,
            size: 17,
          ),
          SizedBox(width: 6),
          Text(
            'LIVE RESPONDER',
            style: TextStyle(
              fontWeight:
                  FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MapPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          const BoxConstraints(
        maxWidth: 230,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.blue,
          ),
          const SizedBox(width: 9),
          Text(
            '$label: ',
            style: TextStyle(
              color:
                  Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign:
                  TextAlign.end,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}