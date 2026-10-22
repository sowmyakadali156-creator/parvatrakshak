import 'dart:math';
import '../models/incident.dart';
import '../models/responder.dart';

class ResponderMatch {
  final Responder responder;
  final int score;
  final double distanceKm;
  final int etaMinutes;
  final int skillScore;
  final int workloadScore;
  final int arrivalRank;

  const ResponderMatch({
    required this.responder,
    required this.score,
    required this.distanceKm,
    required this.etaMinutes,
    required this.skillScore,
    required this.workloadScore,
    required this.arrivalRank,
  });
}

class DispatchEngine {
  static List<ResponderMatch> rank({
    required Incident incident,
    required List<Responder> responders,
    String? preferredDepartment,
    String? excludeResponderId,
    bool includeUnavailable = false,
  }) {
    final candidates = responders.where((r) {
      if ((!r.available && !includeUnavailable) || r.id == excludeResponderId) return false;
      if (preferredDepartment != null && r.department != preferredDepartment) {
        // General Response can back up Disaster Response / Other.
        final backup = preferredDepartment == 'Disaster Response' && r.department == 'General Response';
        if (!backup) return false;
      }
      return true;
    }).map((r) {
      final distance = distanceKm(incident.latitude, incident.longitude, r.latitude, r.longitude);
      final skills = switch (incident.category) {
        IncidentCategory.fire => ['fire', 'rescue'],
        IncidentCategory.medical => ['medical', 'first aid'],
        IncidentCategory.accident => ['medical', 'rescue'],
        IncidentCategory.security => ['security', 'patrol'],
        IncidentCategory.disaster => ['rescue', 'disaster'],
        IncidentCategory.other => ['general', 'rescue'],
      };
      final skillMatch = r.skills.any((s) => skills.contains(s.toLowerCase()));
      final skillScore = skillMatch ? 100 : 25;
      final eta = max(1, (distance * 3.5).ceil());
      final workloadScore = max(0, 100 - r.workload * 25);
      // Arrival time is deliberately the strongest factor for the contest demo.
      final arrivalScore = max(0, 100 - (eta * 12));
      final score = ((arrivalScore * .50) + (skillScore * .30) + (workloadScore * .20)).round().clamp(0, 100).toInt();
      return _Candidate(
        responder: r,
        score: score,
        distanceKm: distance,
        etaMinutes: eta,
        skillScore: skillScore,
        workloadScore: workloadScore,
      );
    }).toList();

    // Explicitly rank primarily by estimated arrival time, then skill/workload.
    candidates.sort((a, b) {
      final eta = a.etaMinutes.compareTo(b.etaMinutes);
      if (eta != 0) return eta;
      final skill = b.skillScore.compareTo(a.skillScore);
      if (skill != 0) return skill;
      return b.score.compareTo(a.score);
    });

    return [
      for (var i = 0; i < candidates.length; i++)
        ResponderMatch(
          responder: candidates[i].responder,
          score: candidates[i].score,
          distanceKm: candidates[i].distanceKm,
          etaMinutes: candidates[i].etaMinutes,
          skillScore: candidates[i].skillScore,
          workloadScore: candidates[i].workloadScore,
          arrivalRank: i + 1,
        ),
    ];
  }

  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return radius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double value) => value * pi / 180;
}

class _Candidate {
  final Responder responder;
  final int score;
  final double distanceKm;
  final int etaMinutes;
  final int skillScore;
  final int workloadScore;

  const _Candidate({
    required this.responder,
    required this.score,
    required this.distanceKm,
    required this.etaMinutes,
    required this.skillScore,
    required this.workloadScore,
  });
}
