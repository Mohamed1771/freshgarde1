import 'package:flutter/foundation.dart';

/// User preferences for the running session.
class SettingsRepository extends ChangeNotifier {
  bool pushNotifications = true;
  bool temperatureAlerts = true;
  bool humidityAlerts = true;
  double alertThresholdC = 3;
  double simulationSpeed = 0.5;

  void update(void Function(SettingsRepository s) change) {
    change(this);
    notifyListeners();
  }
}
