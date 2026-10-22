import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/app_store.dart';
import '../../theme/app_theme.dart';
import '../student/student_home.dart';
import '../responder/responder_home.dart';
import '../admin/command_center.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscure = true;
  bool loading = false;
  String? error;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _fill(String username, String password) {
    setState(() {
      usernameController.text = username;
      passwordController.text = password;
      error = null;
    });
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final ok = AppStore.instance.authenticate(usernameController.text, passwordController.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        loading = false;
        error = 'Invalid username or password.';
      });
      return;
    }
    final role = AppStore.instance.role;
    final page = switch (role) {
      UserRole.student => const StudentHome(),
      UserRole.responder => const ResponderHome(),
      UserRole.admin => const CommandCenter(),
    };
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 850;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF2F7FF), Color(0xFFF9FBFF), Color(0xFFFFF7F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: wide
                    ? Row(children: [Expanded(child: _brand()), const SizedBox(width: 24), Expanded(child: _form())])
                    : _form(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand() {
    return Container(
      padding: const EdgeInsets.all(38),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.navy, AppTheme.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppTheme.blue.withValues(alpha: .18), blurRadius: 35, offset: const Offset(0, 18))],
      ),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.emergency_share_rounded, color: Colors.white, size: 62),
        SizedBox(height: 24),
        Text('RESCUEGRID', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        SizedBox(height: 10),
        Text('One campus. One response network. Every second matters.', style: TextStyle(color: Color(0xFFDCEBFF), fontSize: 17, height: 1.45)),
        SizedBox(height: 28),
        _Feature(icon: Icons.login_rounded, text: 'Secure role-based sign-in'),
        _Feature(icon: Icons.notifications_active_rounded, text: 'Department-specific emergency alerts'),
        _Feature(icon: Icons.auto_awesome_rounded, text: 'Smart severity and responder ranking'),
        _Feature(icon: Icons.sync_problem_rounded, text: 'Automatic escalation when unanswered'),
      ]),
    );
  }

  Widget _form() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Sign in', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900, color: AppTheme.navy)),
          const SizedBox(height: 6),
          Text('Use your campus RescueGrid account.', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 22),
          TextField(controller: usernameController, textInputAction: TextInputAction.next, decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded), labelText: 'Username', hintText: 'Enter username')),
          const SizedBox(height: 13),
          TextField(controller: passwordController, obscureText: obscure, onSubmitted: (_) => _login(), decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline_rounded), labelText: 'Password', hintText: 'Enter password', suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded)))),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFECEC), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.error_outline_rounded, color: AppTheme.red), const SizedBox(width: 8), Expanded(child: Text(error!, style: const TextStyle(color: AppTheme.red, fontWeight: FontWeight.w700))) ])),
          ],
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: loading ? null : _login, icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.login_rounded), label: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(loading ? 'Signing in...' : 'Sign in', style: const TextStyle(fontWeight: FontWeight.w900))))),
          const SizedBox(height: 24),
          const Text('Contest demo accounts', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 9),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _DemoChip(label: 'Student 01', username: 'student01', password: '1234', icon: Icons.school_rounded, onTap: _fill),
            _DemoChip(label: 'Student 02', username: 'student02', password: '1234', icon: Icons.school_rounded, onTap: _fill),
            _DemoChip(label: 'Medical 01', username: 'medical01', password: '1234', icon: Icons.medical_services_rounded, onTap: _fill),
            _DemoChip(label: 'Medical 02', username: 'medical02', password: '1234', icon: Icons.medical_services_rounded, onTap: _fill),
            _DemoChip(label: 'Fire 01', username: 'fire01', password: '1234', icon: Icons.local_fire_department_rounded, onTap: _fill),
            _DemoChip(label: 'Fire 02', username: 'fire02', password: '1234', icon: Icons.local_fire_department_rounded, onTap: _fill),
            _DemoChip(label: 'Security', username: 'security01', password: '1234', icon: Icons.shield_rounded, onTap: _fill),
            _DemoChip(label: 'Command', username: 'admin01', password: 'admin123', icon: Icons.dashboard_rounded, onTap: _fill),
          ]),
          const SizedBox(height: 12),
          Text('Demo credentials are local to this prototype. Use a secure identity provider and hashed passwords in production.', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.35)),
        ]),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Feature({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 15), child: Row(children: [Icon(icon, color: Colors.white, size: 21), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))]));
}

class _DemoChip extends StatelessWidget {
  final String label;
  final String username;
  final String password;
  final IconData icon;
  final void Function(String, String) onTap;
  const _DemoChip({required this.label, required this.username, required this.password, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => ActionChip(avatar: Icon(icon, size: 17, color: AppTheme.blue), label: Text(label), onPressed: () => onTap(username, password));
}
