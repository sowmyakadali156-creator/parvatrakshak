import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/incident.dart';
import '../../services/app_store.dart';
import '../../services/dispatch_engine.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class IncidentDetails extends StatelessWidget {
  final Incident incident;
  final bool showSuccess;

  const IncidentDetails({
    super.key,
    required this.incident,
    this.showSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        final store = AppStore.instance;

        final responder = store.responderById(incident.responderId);

        final distance = responder == null
            ? null
            : DispatchEngine.distanceKm(
                incident.latitude,
                incident.longitude,
                responder.latitude,
                responder.longitude,
              );

        return Scaffold(
          appBar: AppBar(
            title: Text('Incident ${incident.id}'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SeverityBadge(
                  severity: incident.severity,
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final infoSection = _buildMainInfo(
                context,
                responder,
                distance,
              );

              final timelineSection = _buildTimeline(
                context,
                responder,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  30,
                ),
                child: constraints.maxWidth >= 900
                    ? Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: infoSection,
                          ),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 370,
                            child: timelineSection,
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          infoSection,
                          const SizedBox(height: 18),
                          timelineSection,
                        ],
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMainInfo(
    BuildContext context,
    dynamic responder,
    double? distance,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSuccess)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F8F0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.green,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Emergency submitted successfully. You will receive notifications as the response progresses.',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (incident.isDuplicateReport)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.content_copy_rounded,
                  color: Colors.orange,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Duplicate report detected. Your report has been linked to the existing emergency, so another responder was not dispatched.',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor:
                          incident.severityColor.withValues(
                        alpha: 0.10,
                      ),
                      child: Icon(
                        incident.category.icon,
                        color: incident.severityColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.category.label,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            incident.locationLabel,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SeverityBadge(
                      severity: incident.severity,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: incident.severityColor
                        .withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Severity assessment',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${incident.severityScore}/100',
                        style: TextStyle(
                          color: incident.severityColor,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _InfoRow(
                  icon: Icons.groups_rounded,
                  label: 'Student reports',
                  value: '${incident.reporterCount}',
                ),

                _InfoRow(
                  icon: Icons.business_rounded,
                  label: 'Department',
                  value: incident.department,
                ),

                _InfoRow(
                  icon: Icons.person_rounded,
                  label: 'Responder',
                  value: responder?.name ?? 'Being assigned',
                ),

                if (distance != null)
                  _InfoRow(
                    icon: Icons.social_distance_rounded,
                    label: 'Live distance',
                    value:
                        '${distance.toStringAsFixed(2)} km',
                  ),

                const SizedBox(height: 5),

                Text(
                  incident.description,
                  style: const TextStyle(
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        _MapCard(
          incident: incident,
          responder: responder,
        ),
      ],
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    dynamic responder,
  ) {
    return Column(
      children: [
        if (responder != null)
          Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F0FF),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: AppTheme.blue,
                ),
              ),
              title: const Text(
                'Live responder',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                '${responder.name}\n'
                '${responder.latitude.toStringAsFixed(5)}, '
                '${responder.longitude.toStringAsFixed(5)}',
              ),
              trailing: Text(
                incident.status.label,
                style: TextStyle(
                  color: incident.status.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),

        if (responder != null)
          const SizedBox(height: 14),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Incident timeline',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
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
}

class _MapCard extends StatelessWidget {
  final Incident incident;
  final dynamic responder;

  const _MapCard({
    required this.incident,
    required this.responder,
  });

  @override
  Widget build(BuildContext context) {
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

    final distance = responder == null
        ? null
        : DispatchEngine.distanceKm(
            incident.latitude,
            incident.longitude,
            responder.latitude,
            responder.longitude,
          );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 330,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: incidentPoint,
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
                        strokeWidth: 5,
                        color: AppTheme.blue,
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: incidentPoint,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.red,
                        size: 46,
                      ),
                    ),

                    if (responderPoint != null)
                      Marker(
                        point: responderPoint,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: AppTheme.blue,
                          size: 38,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MapPill(
                    icon: Icons.location_on_rounded,
                    text: incident.locationLabel,
                  ),

                  if (distance != null)
                    _MapPill(
                      icon:
                          Icons.social_distance_rounded,
                      text:
                          '${distance.toStringAsFixed(2)} km away',
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
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
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
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
          const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
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
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}