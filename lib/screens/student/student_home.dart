import 'package:flutter/material.dart';
import '../../services/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/common_widgets.dart';
import 'report_emergency.dart';
import 'incident_details.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppStore.instance,
      builder: (context, _) {
        return AppShell(
          role: AppStore.instance.role,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
          pages: const [
            _StudentDashboard(),
            _StudentReports(),
            _StudentProfile(),
          ],
        );
      },
    );
  }
}

class _StudentDashboard extends StatelessWidget {
  const _StudentDashboard();

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final active = store.myIncidents.where((i) => i.isActive).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        GradientHeader(
          eyebrow: 'Campus safety',
          title: 'Stay safe, stay connected.',
          subtitle:
              'Report an emergency in seconds. RescueGrid handles location, severity and dispatch.',
          icon: Icons.shield_rounded,
        ),
        const SizedBox(height: 18),
        _EmergencyButton(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportEmergency()),
            );
          },
        ),
        const SizedBox(height: 14),
        _StudentNotificationBanner(unread: store.unreadNotificationCount),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                'My reports',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '${store.myIncidents.length}',
              style: const TextStyle(
                color: AppTheme.blue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (active.isEmpty)
          const EmptyState(
            icon: Icons.verified_user_rounded,
            title: 'No active emergencies',
            subtitle: 'Your campus is currently clear. We are ready if you need us.',
          )
        else
          ...active.take(3).map(
                (incident) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: IncidentCard(
                    incident: incident,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IncidentDetails(incident: incident),
                      ),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 18),
        if (store.myIncidents.any((i) => i.isDuplicateReport)) ...[
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.orange.withValues(alpha: .25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.content_copy_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Expanded(child: Text('Some reports were linked as duplicates. This prevents multiple responders from being sent to the same emergency.', style: TextStyle(fontWeight: FontWeight.w700))),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        const Text(
          'How RescueGrid works',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        const _FlowCard(
          number: '01',
          icon: Icons.report_problem_rounded,
          title: 'Report',
          subtitle: 'Category, photo, description and GPS in one flow.',
        ),
        const _FlowCard(
          number: '02',
          icon: Icons.auto_awesome_rounded,
          title: 'Smart dispatch',
          subtitle: 'Severity and responder ranking happen automatically.',
        ),
        const _FlowCard(
          number: '03',
          icon: Icons.route_rounded,
          title: 'Respond',
          subtitle: 'Track progress from assignment to resolution.',
        ),
      ],
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EmergencyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD92323), Color(0xFFFF6B35)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: .22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 29,
              backgroundColor: Colors.white24,
              child: Icon(
                Icons.sos_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REPORT AN EMERGENCY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Fast reporting • GPS • Smart dispatch',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}


class _StudentNotificationBanner extends StatelessWidget {
  final int unread;
  const _StudentNotificationBanner({required this.unread});

  @override
  Widget build(BuildContext context) {
    final color = unread > 0 ? AppTheme.blue : AppTheme.green;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(children: [
        Icon(unread > 0 ? Icons.notifications_active_rounded : Icons.verified_rounded, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(unread > 0 ? '$unread new response notification${unread == 1 ? '' : 's'} waiting in the bell icon.' : 'You will receive a notification whenever your emergency changes status.', style: const TextStyle(fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

class _FlowCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String subtitle;

  const _FlowCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: AppTheme.blue.withValues(alpha: .1),
          child: Icon(icon, color: AppTheme.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: Text(
          number,
          style: TextStyle(
            color: Colors.grey.shade300,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ),
    );
  }
}

class _StudentReports extends StatelessWidget {
  const _StudentReports();

  @override
  Widget build(BuildContext context) {
    final incidents = AppStore.instance.myIncidents;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        const Text(
          'My reports',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Every report is tracked from submission to resolution.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 18),
        if (incidents.isEmpty)
          const EmptyState(
            icon: Icons.assignment_rounded,
            title: 'No reports yet',
            subtitle: 'Your submitted emergencies will appear here.',
          )
        else
          ...incidents.map(
            (incident) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: IncidentCard(
                incident: incident,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IncidentDetails(incident: incident),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StudentProfile extends StatelessWidget {
  const _StudentProfile();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Profile',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 31,
                  backgroundColor: Color(0xFFE8F0FF),
                  child: Icon(Icons.school_rounded,
                      color: AppTheme.blue, size: 30),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStore.instance.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Student • Campus ID RG-STU-24',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.location_on_rounded),
                title: Text('Location access'),
                subtitle: Text('Used only while reporting an emergency'),
                trailing: Icon(Icons.check_circle_rounded, color: Colors.green),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.notifications_active_rounded),
                title: Text('Emergency notifications'),
                subtitle: Text('Assignment and status updates'),
                trailing: Icon(Icons.check_circle_rounded, color: Colors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
