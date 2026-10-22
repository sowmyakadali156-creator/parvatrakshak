import 'responder.dart';

enum UserRole { student, responder, admin }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.student => 'Student',
        UserRole.responder => 'Responder',
        UserRole.admin => 'Command Center',
      };
}

class AppUser {
  final String id;
  final String username;
  final String password; // Demo only. Never store plaintext passwords in production.
  final String name;
  final UserRole role;
  final String? department;
  final String? responderId;

  const AppUser({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.role,
    this.department,
    this.responderId,
  });
}
