class Responder {
  final String id;
  final String name;
  final String type;
  final String username;
  final String department;
  final List<String> skills;
  bool available;
  double latitude;
  double longitude;
  int workload;

  Responder({
    required this.id,
    required this.name,
    required this.type,
    required this.username,
    required this.department,
    required this.skills,
    required this.available,
    required this.latitude,
    required this.longitude,
    required this.workload,
  });
}
