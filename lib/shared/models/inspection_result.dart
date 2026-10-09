import 'package:flutter/material.dart';

/// Six visual maturity stages, aligned with the stages used by the Three.js simulation (1..6).
enum MaturityStage {
  matureGreen(1, 'أخضر ناضج', 'mature_green', Color(0xFF6AA843)),
  breaker(2, 'بداية التلوّن', 'breaker', Color(0xFFB4B44C)),
  turning(3, 'متحوّل / أحمر فاتح', 'turning', Color(0xFFEA8C2C)),
  ripe(4, 'ناضج', 'ripe', Color(0xFFD33A22)),
  overripe(5, 'مفرط النضج', 'overripe', Color(0xFF8C1F17)),
  spoiled(6, 'تالف', 'spoiled', Color(0xFF5A3A22));

  const MaturityStage(this.simStage, this.label, this.apiKey, this.color);

  /// Stage index used by `FreshRouteAPI.applyPrediction` in the Three.js scene.
  final int simStage;
  final String label;
  final String apiKey;
  final Color color;

  static MaturityStage fromSimStage(int s) => values[(s.clamp(1, 6)) - 1];

  static MaturityStage fromApi(String key) => values.firstWhere(
        (s) => s.apiKey == key.toLowerCase().trim().replaceAll(' ', '_'),
        orElse: () => ripe,
      );

  /// Starting ripeness (0..1) and deterioration (0..1) used to seed the simulation.
  /// Kept as two separate variables on purpose: ripening is not decay.
  (double ripeness, double deterioration) get seed => switch (this) {
        matureGreen => (0.05, 0.0),
        breaker => (0.25, 0.0),
        turning => (0.50, 0.02),
        ripe => (0.80, 0.04),
        overripe => (0.97, 0.20),
        spoiled => (1.0, 0.55),
      };
}

enum MediaType { image, video }

class DetectedDefect {
  const DetectedDefect({required this.label, required this.severity, required this.areaPct});

  final String label;

  /// 0..1
  final double severity;

  /// Share of the visible surface affected, 0..100.
  final double areaPct;

  factory DetectedDefect.fromJson(Map<String, dynamic> j) => DetectedDefect(
        label: j['label'] as String,
        severity: (j['severity'] as num).toDouble(),
        areaPct: (j['area_pct'] as num? ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {'label': label, 'severity': severity, 'area_pct': areaPct};
}

/// Typed result of a product inspection. Matches the JSON contract expected from the FastAPI service:
///
/// ```json
/// {
///   "product": "tomato",
///   "maturity_stage": "turning",
///   "confidence": 0.91,
///   "quality_score": 84.0,
///   "defects": [{"label": "bruise", "severity": 0.3, "area_pct": 2.5}],
///   "recommendation": "...",
///   "model_version": "yolov8-tomato-1.2",
///   "simulated": false
/// }
/// ```
class InspectionResult {
  const InspectionResult({
    required this.id,
    required this.mediaType,
    required this.fileName,
    required this.detectedProduct,
    required this.maturityStage,
    required this.confidence,
    required this.qualityScore,
    required this.defects,
    required this.recommendation,
    required this.modelVersion,
    required this.isSimulated,
    required this.createdAt,
  });

  final String id;
  final MediaType mediaType;
  final String fileName;
  final String detectedProduct;
  final MaturityStage maturityStage;

  /// 0..1
  final double confidence;

  /// 0..100
  final double qualityScore;
  final List<DetectedDefect> defects;
  final String recommendation;
  final String modelVersion;

  /// True when the result was produced by [MockAiInspectionService] and not by a real model.
  final bool isSimulated;
  final DateTime createdAt;

  /// Extra deterioration implied by visible defects, added to the simulation seed.
  double get defectDeterioration =>
      defects.fold(0.0, (s, d) => s + d.severity * d.areaPct / 100).clamp(0.0, 0.3);

  factory InspectionResult.fromJson(Map<String, dynamic> j, {required MediaType mediaType, required String fileName}) =>
      InspectionResult(
        id: j['id'] as String? ?? 'INS-${DateTime.now().millisecondsSinceEpoch}',
        mediaType: mediaType,
        fileName: fileName,
        detectedProduct: j['product'] as String,
        maturityStage: MaturityStage.fromApi(j['maturity_stage'] as String),
        confidence: (j['confidence'] as num).toDouble(),
        qualityScore: (j['quality_score'] as num? ?? 0).toDouble(),
        defects: (j['defects'] as List? ?? const [])
            .map((e) => DetectedDefect.fromJson(e as Map<String, dynamic>))
            .toList(),
        recommendation: j['recommendation'] as String? ?? '',
        modelVersion: j['model_version'] as String? ?? 'unknown',
        isSimulated: j['simulated'] as bool? ?? false,
        createdAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'media_type': mediaType.name,
        'file_name': fileName,
        'product': detectedProduct,
        'maturity_stage': maturityStage.apiKey,
        'confidence': confidence,
        'quality_score': qualityScore,
        'defects': defects.map((d) => d.toJson()).toList(),
        'recommendation': recommendation,
        'model_version': modelVersion,
        'simulated': isSimulated,
        'created_at': createdAt.toIso8601String(),
      };
}
