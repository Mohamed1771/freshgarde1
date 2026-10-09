import 'dart:typed_data';

import '../models/inspection_result.dart';

/// A media file selected by the user for inspection. Bytes stay in memory only.
class InspectionMedia {
  const InspectionMedia({required this.name, required this.bytes, required this.type, this.mimeType});

  final String name;
  final Uint8List bytes;
  final MediaType type;
  final String? mimeType;

  int get sizeBytes => bytes.length;
  String get sizeLabel => sizeBytes > 1024 * 1024
      ? '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB'
      : '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
}

class InspectionException implements Exception {
  InspectionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Contract for product quality inspection. Screens depend only on this interface.
///
/// Implementations:
/// * [MockAiInspectionService] — predictable demo output, clearly marked as simulated.
/// * `FastApiInspectionService` — calls the Python model (`POST /predict/image`, `POST /predict/video`).
abstract interface class AiInspectionService {
  /// Short label shown in the UI so users always know which engine produced a result.
  String get engineLabel;

  /// True when results do not come from a real model.
  bool get isSimulated;

  Future<InspectionResult> analyzeImage(InspectionMedia media, {String? productHint});
  Future<InspectionResult> analyzeVideo(InspectionMedia media, {String? productHint});
}

/// Deterministic mock: the same file always yields the same result. It does NOT run any model;
/// it derives a demo result from a checksum of the file so the flow can be demonstrated end to end.
class MockAiInspectionService implements AiInspectionService {
  const MockAiInspectionService();

  @override
  String get engineLabel => 'خدمة محاكاة (بدون نموذج AI حقيقي)';

  @override
  bool get isSimulated => true;

  @override
  Future<InspectionResult> analyzeImage(InspectionMedia media, {String? productHint}) =>
      _analyze(media, productHint, const Duration(milliseconds: 1800));

  @override
  Future<InspectionResult> analyzeVideo(InspectionMedia media, {String? productHint}) =>
      _analyze(media, productHint, const Duration(milliseconds: 2800));

  Future<InspectionResult> _analyze(InspectionMedia media, String? hint, Duration latency) async {
    await Future<void>.delayed(latency);
    if (media.bytes.isEmpty) throw InspectionException('الملف فارغ أو تعذّرت قراءته.');

    final seed = _checksum(media);
    // Stages 1..5 for the demo; "spoiled" only appears for files whose name says so.
    final stage = media.name.toLowerCase().contains('spoil')
        ? MaturityStage.spoiled
        : MaturityStage.values[seed % 5];
    final confidence = 0.78 + (seed % 17) / 100;
    final defects = _defectsFor(stage, seed);
    final quality = (98 - stage.simStage * 4 - defects.fold<double>(0, (s, d) => s + d.severity * d.areaPct)).clamp(15.0, 98.0);

    return InspectionResult(
      id: 'INS-${DateTime.now().millisecondsSinceEpoch % 100000}',
      mediaType: media.type,
      fileName: media.name,
      detectedProduct: hint ?? 'tomato',
      maturityStage: stage,
      confidence: double.parse(confidence.toStringAsFixed(2)),
      qualityScore: double.parse(quality.toStringAsFixed(1)),
      defects: defects,
      recommendation: _recommendationFor(stage),
      modelVersion: media.type == MediaType.video ? 'mock-simulated-v1 (12 إطارًا)' : 'mock-simulated-v1',
      isSimulated: true,
      createdAt: DateTime.now(),
    );
  }

  int _checksum(InspectionMedia m) {
    var h = m.name.length * 31 + m.bytes.length;
    final step = (m.bytes.length ~/ 64).clamp(1, 1 << 20);
    for (var i = 0; i < m.bytes.length; i += step) {
      h = (h * 31 + m.bytes[i]) & 0x7fffffff;
    }
    return h;
  }

  List<DetectedDefect> _defectsFor(MaturityStage s, int seed) => switch (s) {
        MaturityStage.matureGreen || MaturityStage.breaker => [
            if (seed % 3 == 0) const DetectedDefect(label: 'خدوش سطحية', severity: 0.15, areaPct: 1.5),
          ],
        MaturityStage.turning || MaturityStage.ripe => [
            const DetectedDefect(label: 'كدمات خفيفة', severity: 0.25, areaPct: 3),
            if (seed % 2 == 0) const DetectedDefect(label: 'تشقق قرب العنق', severity: 0.2, areaPct: 1),
          ],
        MaturityStage.overripe => const [
            DetectedDefect(label: 'ليونة زائدة', severity: 0.45, areaPct: 12),
            DetectedDefect(label: 'بقع داكنة', severity: 0.35, areaPct: 5),
          ],
        MaturityStage.spoiled => const [
            DetectedDefect(label: 'عفن', severity: 0.85, areaPct: 22),
            DetectedDefect(label: 'تجعّد القشرة', severity: 0.5, areaPct: 15),
          ],
      };

  String _recommendationFor(MaturityStage s) => switch (s) {
        MaturityStage.matureGreen => 'منتج غير ناضج وحساس للبرودة: يُنصح بضبط 12.5–13°C وتجنّب أقل من 10°C.',
        MaturityStage.breaker => 'مناسب للرحلات الطويلة: 12°C ورطوبة 90%.',
        MaturityStage.turning => 'يُنصح بـ 11.5–12°C لإبطاء النضج حتى الوصول.',
        MaturityStage.ripe => 'ناضج: خفّض إلى 10–11°C وأعطِ الأولوية للتسليم السريع.',
        MaturityStage.overripe => 'مفرط النضج: يُنصح بالبيع الفوري أو التوجيه لسوق قريب.',
        MaturityStage.spoiled => 'تلف واضح: افرز الصناديق المتضررة قبل التحميل.',
      };
}
