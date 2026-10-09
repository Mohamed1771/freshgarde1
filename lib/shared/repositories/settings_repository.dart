import 'package:flutter/foundation.dart';

import '../services/ai_inspection_service.dart';
import '../services/fastapi_inspection_service.dart';

enum AiEngine {
  mock('خدمة المحاكاة (افتراضي)'),
  fastApi('نموذج Python عبر FastAPI');

  const AiEngine(this.label);
  final String label;
}

/// User preferences for the running session, plus the factory for the active AI service.
class SettingsRepository extends ChangeNotifier {
  bool pushNotifications = true;
  bool temperatureAlerts = true;
  bool humidityAlerts = true;
  double alertThresholdC = 3;
  double simulationSpeed = 0.5;
  AiEngine aiEngine = AiEngine.mock;
  String apiBaseUrl = 'http://10.0.2.2:8000';

  AiInspectionService get aiService => switch (aiEngine) {
        AiEngine.mock => const MockAiInspectionService(),
        AiEngine.fastApi => FastApiInspectionService(baseUrl: apiBaseUrl),
      };

  void update(void Function(SettingsRepository s) change) {
    change(this);
    notifyListeners();
  }
}
