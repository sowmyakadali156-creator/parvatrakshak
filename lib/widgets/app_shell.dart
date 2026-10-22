import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/notification.dart';
import '../services/app_store.dart';
import '../theme/app_theme.dart';
import '../screens/auth/login_screen.dart';

class AppShell extends StatefulWidget {
  final UserRole role;
  final List<NavigationDestination> destinations;
  final List<NavigationRailDestination>? railDestinations;
  final List<Widget> pages;
  final int initialIndex;

  const AppShell({super.key, required this.role, required this.destinations, required this.pages, this.railDestinations, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int index;
  @override
  void initState() { super.initState(); index = widget.initialIndex; }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final store = AppStore.instance;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.blue, AppTheme.cyan]), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 20)), const SizedBox(width: 10), const Text('RescueGrid', style: TextStyle(fontWeight: FontWeight.w900))]),
        actions: [
          _NotificationButton(count: store.unreadNotificationCount, onTap: () => _showNotifications(context)),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'logout') {
                store.logout();
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text('${store.userName}\n${widget.role.label}', style: const TextStyle(fontWeight: FontWeight.w700))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout_rounded), SizedBox(width: 10), Text('Sign out')]))
            ],
            child: const Padding(padding: EdgeInsets.all(8), child: CircleAvatar(backgroundColor: Color(0xFFE8F0FF), child: Icon(Icons.person_rounded, color: AppTheme.blue))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(children: [
        if (wide) NavigationRail(selectedIndex: index, onDestinationSelected: (value) => setState(() => index = value), labelType: NavigationRailLabelType.all, backgroundColor: Colors.white, leading: const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Icon(Icons.shield_rounded, color: AppTheme.blue)), destinations: widget.railDestinations ?? widget.destinations.map((d) => NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: Text(d.label))).toList()),
        Expanded(child: IndexedStack(index: index, children: widget.pages)),
      ]),
      bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: index, onDestinationSelected: (value) => setState(() => index = value), destinations: widget.destinations),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NotificationSheet(notifications: AppStore.instance.myNotifications),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NotificationButton({required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [IconButton(tooltip: 'Notifications', onPressed: onTap, icon: const Icon(Icons.notifications_none_rounded, size: 27)), if (count > 0) Positioned(right: 5, top: 5, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: AppTheme.red, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 1.5)), child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))))]);
}

class _NotificationSheet extends StatelessWidget {
  final List<AppNotification> notifications;
  const _NotificationSheet({required this.notifications});
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * .72;
    return SizedBox(height: height, child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 0, 12, 12), child: Row(children: [const Expanded(child: Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))), TextButton(onPressed: () { AppStore.instance.markAllNotificationsRead(); Navigator.pop(context); }, child: const Text('Mark all read'))])),
      const Divider(height: 1),
      Expanded(child: notifications.isEmpty ? const Center(child: Text('No notifications yet.')) : ListView.separated(padding: const EdgeInsets.all(14), itemCount: notifications.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) { final n = notifications[i]; return Card(color: n.read ? Colors.white : n.color.withValues(alpha: .06), child: ListTile(leading: CircleAvatar(backgroundColor: n.color.withValues(alpha: .12), child: Icon(n.icon, color: n.color)), title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(n.message)), trailing: n.read ? null : const Icon(Icons.circle, color: AppTheme.red, size: 9), onTap: () => AppStore.instance.markNotificationRead(n.id))); }))
    ]));
  }
}
