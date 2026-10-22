import '../models/incident.dart';

class SeverityResult {
  final int score;
  final String level;
  final List<String> reasons;

  const SeverityResult({
    required this.score,
    required this.level,
    required this.reasons,
  });
}

class SeverityEngine {
  static SeverityResult evaluate({
    required IncidentCategory category,
    required int peopleAffected,
    required bool highRiskLocation,
    required bool isNight,
    required String description,
  }) {
    var score = 0;
    final reasons = <String>[];

    switch (category) {
      case IncidentCategory.fire:
        score += 40;
        reasons.add('Fire category');
      case IncidentCategory.medical:
        score += 35;
        reasons.add('Medical emergency');
      case IncidentCategory.accident:
        score += 30;
        reasons.add('Accident reported');
      case IncidentCategory.security:
        score += 25;
        reasons.add('Security incident');
      case IncidentCategory.disaster:
        score += 35;
        reasons.add('Disaster risk');
      case IncidentCategory.other:
        score += 10;
    }

    if (peopleAffected >= 10) {
      score += 30;
      reasons.add('10+ people affected');
    } else if (peopleAffected >= 6) {
      score += 20;
      reasons.add('6–9 people affected');
    } else if (peopleAffected >= 2) {
      score += 10;
      reasons.add('Multiple people affected');
    } else {
      score += 5;
      reasons.add('Single person affected');
    }

    if (highRiskLocation) {
      score += 20;
      reasons.add('High-risk campus zone');
    } else {
      score += 5;
    }

    if (isNight) {
      score += 10;
      reasons.add('Night-time incident');
    }

    final lower = description.toLowerCase();
    const criticalKeywords = [
      'unconscious',
      'smoke',
      'trapped',
      'explosion',
      'bleeding',
      'weapon',
      'collapse',
    ];
    if (criticalKeywords.any(lower.contains)) {
      score += 10;
      reasons.add('Critical keyword detected');
    }

    score = score.clamp(0, 100).toInt();
    final level = score >= 75
        ? 'CRITICAL'
        : score >= 50
            ? 'HIGH'
            : score >= 25
                ? 'MEDIUM'
                : 'LOW';

    return SeverityResult(score: score, level: level, reasons: reasons);
  }
}
