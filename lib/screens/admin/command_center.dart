import 'package:flutter/material.dart';
import '../../models/incident.dart';
import '../../services/app_store.dart';
import '../../services/dispatch_engine.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common_widgets.dart';
import '../responder/active_incident.dart';

class CommandCenter extends StatelessWidget {
  const CommandCenter({super.key});

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
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.warning_amber_outlined),
              selectedIcon: Icon(Icons.warning_rounded),
              label: 'Incidents',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Responders',
            ),
          ],
          pages: const [
            _Overview(),
            _IncidentMonitor(),
            _ResponderMonitor(),
          ],
        );
      },
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview();

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final active = store.activeIncidents;
    final critical = active.where((i) => i.severity == 'CRITICAL').length;
    final assigned = active.where((i) => i.responderId != null).length;
    final available = store.responders.where((r) => r.available).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        const GradientHeader(
          eyebrow: 'Command center',
          title: 'Campus response, one view.',
          subtitle:
              'Monitor incidents, dispatch coverage and response progress from a single operational dashboard.',
          icon: Icons.monitor_heart_rounded,
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth >= 900 ? 4 : 2;
            return GridView.count(
              crossAxisCount: count,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: constraints.maxWidth >= 900 ? 1.9 : 1.55,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  label: 'Active',
                  value: '${active.length}',
                  icon: Icons.warning_rounded,
                  color: AppTheme.blue,
                ),
                StatCard(
                  label: 'Critical',
                  value: '$critical',
                  icon: Icons.priority_high_rounded,
                  color: AppTheme.red,
                ),
                StatCard(
                  label: 'Assigned',
                  value: '$assigned',
                  icon: Icons.assignment_ind_rounded,
                  color: Colors.deepPurple,
                ),
                StatCard(
                  label: 'Available',
                  value: '$available',
                  icon: Icons.radio_button_checked_rounded,
                  color: AppTheme.green,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Live incident board',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              'LIVE',
              style: TextStyle(
                color: AppTheme.green,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (active.isEmpty)
          const EmptyState(
            icon: Icons.verified_rounded,
            title: 'All clear',
            subtitle: 'No active emergencies are currently being handled.',
          )
        else
          ...active.take(4).map(
                (incident) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: IncidentCard(
                    incident: incident,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActiveIncident(incident: incident),
                      ),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 10),
        if (active.isNotEmpty) _SmartDispatchCard(incident: active.first),
      ],
    );
  }
}

class _SmartDispatchCard extends StatelessWidget {
  final Incident incident;

  const _SmartDispatchCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    final matches = DispatchEngine.rank(
      incident: incident,
      responders: AppStore.instance.responders,
      preferredDepartment: incident.department,
      includeUnavailable: true,
    );
    final assigned = AppStore.instance.responderById(incident.responderId);
    final best = matches.isEmpty ? null : matches.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppTheme.blue),
                SizedBox(width: 8),
                Text(
                  'Smart dispatch recommendation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Rank #1 is the fastest estimated arrival. Skill and workload break ties.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (assigned != null) ...[
              const SizedBox(height: 17),
              ResponderMiniCard(responder: assigned),
              const SizedBox(height: 10),
              const _AssignedPill(),
            ] else if (best != null) ...[
              const SizedBox(height: 17),
              ResponderMiniCard(
                responder: best.responder,
                score: best.score,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Metric(label: 'Skill', value: '${best.skillScore}%'),
                  _Metric(
                    label: 'Distance',
                    value: '${best.distanceKm.toStringAsFixed(1)} km',
                  ),
                  _Metric(label: 'ETA', value: '${best.etaMinutes} min'),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Text('Arrival ranking', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ...matches.take(3).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(children: [
                CircleAvatar(radius: 14, backgroundColor: m.arrivalRank == 1 ? AppTheme.orange.withValues(alpha: .12) : const Color(0xFFF3F5F8), child: Text('#${m.arrivalRank}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900))),
                const SizedBox(width: 8),
                Expanded(child: Text(m.responder.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                Text('${m.etaMinutes} min • ${m.distanceKm.toStringAsFixed(2)} km', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}


class _AssignedPill extends StatelessWidget {
  const _AssignedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7F0),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 18),
          SizedBox(width: 8),
          Text(
            'Responder already assigned • monitoring response',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _IncidentMonitor extends StatefulWidget {
  const _IncidentMonitor();

  @override
  State<_IncidentMonitor> createState() => _IncidentMonitorState();
}

class _IncidentMonitorState extends State<_IncidentMonitor> {
  String filter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final all = AppStore.instance.incidents;
    final list = all.where((incident) {
      return switch (filter) {
        'ALL' => true,
        'CRITICAL' => incident.severity == 'CRITICAL',
        'ACTIVE' => incident.isActive,
        'UNASSIGNED' => incident.responderId == null,
        _ => true,
      };
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        const Text(
          'Incident monitor',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Filter the response queue by operational priority.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ALL', 'CRITICAL', 'ACTIVE', 'UNASSIGNED']
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(item),
                      selected: filter == item,
                      onSelected: (_) => setState(() => filter = item),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching incidents',
            subtitle: 'Try another operational filter.',
          )
        else
          ...list.map(
            (incident) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: IncidentCard(
                incident: incident,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveIncident(incident: incident),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ResponderMonitor extends StatelessWidget {
  const _ResponderMonitor();

  @override
  Widget build(BuildContext context) {
    final responders = AppStore.instance.responders;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        const Text(
          'Responder network',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Availability, skills and workload used by smart dispatch.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 18),
        ...responders.map(
          (responder) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: responder.available
                        ? const Color(0xFFE8F7F0)
                        : const Color(0xFFFFECEC),
                    child: Icon(
                      responder.available
                          ? Icons.radio_button_checked_rounded
                          : Icons.pause_circle_rounded,
                      color: responder.available
                          ? AppTheme.green
                          : AppTheme.red,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          responder.name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          responder.skills.join(' • '),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        responder.available ? 'AVAILABLE' : 'BUSY',
                        style: TextStyle(
                          color: responder.available
                              ? AppTheme.green
                              : AppTheme.red,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Load ${responder.workload}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${responder.latitude.toStringAsFixed(5)}, ${responder.longitude.toStringAsFixed(5)}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
