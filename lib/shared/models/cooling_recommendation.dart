enum RecommendationPriority {
  info('معلومة'),
  advisory('مستحسن'),
  urgent('عاجل');

  const RecommendationPriority(this.label);
  final String label;
}

/// A cooling action suggested by the decision layer (rule-based in this demo).
class CoolingRecommendation {
  const CoolingRecommendation({
    required this.title,
    required this.detail,
    required this.priority,
    this.targetSetpointC,
  });

  final String title;
  final String detail;
  final RecommendationPriority priority;
  final double? targetSetpointC;
}
