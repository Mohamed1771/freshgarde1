import 'dart:async';

import '../../shared/models/shipment.dart';
import '../../shared/models/simulation_state.dart';
import '../../shared/repositories/settings_repository.dart';
import '../../shared/repositories/shipment_repository.dart';
import 'mock_simulation_bridge.dart';
import 'mock_simulation_engine.dart';

/// Keeps one live simulation per shipment for the whole app session.
///
/// Active shipments run on their own (no user controls) following their scenario; pending shipments
/// wait at hour 0; delivered / archived shipments show the completed trip. Results are written back
/// into the shipment (telemetry, quality, forecast, alerts) so every screen sees the same data.
class LiveSimulationService {
  LiveSimulationService(this._repo, this._settings);

  final ShipmentRepository _repo;
  final SettingsRepository _settings;
  final Map<String, LiveSession> _sessions = {};

  LiveSession sessionFor(Shipment s) => _sessions.putIfAbsent(s.id, () => LiveSession._(s, _repo, _settings));

  /// Moves a pending shipment on the road and starts its live trip.
  void startTrip(Shipment s) {
    _repo.setStatus(s, ShipmentStatus.active);
    sessionFor(s).syncWithStatus();
  }

  void setStatus(Shipment s, ShipmentStatus status) {
    _repo.setStatus(s, status);
    _sessions[s.id]?.syncWithStatus();
  }

  void dispose() {
    for (final s in _sessions.values) {
      s.dispose();
    }
    _sessions.clear();
  }
}

class LiveSession {
  LiveSession._(this.shipment, this._repo, SettingsRepository settings)
      : bridge = MockSimulationBridge(speedHoursPerSecond: settings.simulationSpeed, alertThresholdC: settings.alertThresholdC) {
    _sub = bridge.onSimulationStateChanged.listen(_onState);
    bridge.initializeShipment(shipment);
    _active = _keysOf(bridge.state);
    syncWithStatus();
  }

  /// Minimum simulated time between two alerts of the same shipment.
  static const minGapHours = 2.0;

  /// Minimum real time between two alert notifications.
  static const minGapReal = Duration(minutes: 1);

  /// The same kind of alert is not repeated within this simulated window (avoids flapping
  /// around a threshold, e.g. humidity hovering at 82%).
  static const repeatCooldownHours = 8.0;

  final Shipment shipment;
  final ShipmentRepository _repo;
  final MockSimulationBridge bridge;
  late final StreamSubscription<SimulationState> _sub;
  final _alerts = StreamController<String>.broadcast();
  Map<String, String> _active = {};
  final Map<String, String> _queue = {};
  final Map<String, double> _firedAt = {};
  double _lastFiredHour = -1e9;
  DateTime _lastFiredReal = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastPersist = DateTime.fromMillisecondsSinceEpoch(0);

  /// New alerts raised while the trip runs (for SnackBars on the visible screen).
  Stream<String> get newAlerts => _alerts.stream;

  SimulationState get state => bridge.state;

  void syncWithStatus() {
    switch (shipment.status) {
      case ShipmentStatus.active:
        if (bridge.hour == 0 && shipment.progress > 0.02) {
          bridge.setTime(shipment.progress * MockSimulationEngine.tripHours);
        }
        if (!bridge.playing) bridge.start();
      case ShipmentStatus.pending:
        if (bridge.playing) bridge.pause();
      case ShipmentStatus.delivered || ShipmentStatus.archived:
        if (bridge.playing) bridge.pause();
        if (bridge.hour < MockSimulationEngine.tripHours) bridge.setTime(MockSimulationEngine.tripHours);
    }
    _active = _keysOf(bridge.state);
    _queue.clear();
  }

  /// Alert kind without its changing numbers, so "الرطوبة 82%" and "الرطوبة 81%" are the same alert.
  static String _keyOf(String alert) => alert.replaceAll(RegExp(r'[\d.,%°C\u200E]+'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  static Map<String, String> _keysOf(SimulationState s) => {for (final a in s.alerts) _keyOf(a): a};

  static bool _isCritical(String a) => a.contains('عطل') || a.contains('أعلى من') || a.contains('مفتوح');

  void _onState(SimulationState s) {
    if (shipment.status != ShipmentStatus.active) return;

    // 1. Queue alerts that just appeared (unless the same kind fired recently).
    final current = _keysOf(s);
    for (final e in current.entries) {
      final last = _firedAt[e.key];
      if (!_active.containsKey(e.key) && (last == null || s.hour - last >= repeatCooldownHours)) _queue[e.key] = e.value;
    }
    _active = current;
    // Keep queued text up to date and drop alerts whose condition already ended.
    _queue.removeWhere((k, _) => !current.containsKey(k));
    for (final k in _queue.keys) {
      _queue[k] = current[k]!;
    }

    // 2. Release at most one alert, spaced in both simulated and real time; critical ones first.
    var fired = false;
    if (_queue.isNotEmpty &&
        s.hour - _lastFiredHour >= minGapHours &&
        DateTime.now().difference(_lastFiredReal) >= minGapReal) {
      final key = _queue.keys.firstWhere((k) => _isCritical(_queue[k]!), orElse: () => _queue.keys.first);
      final msg = _queue.remove(key)!;
      _firedAt[key] = s.hour;
      _lastFiredHour = s.hour;
      _lastFiredReal = DateTime.now();
      fired = true;
      _repo.addSimulationAlert(shipment, msg, _isCritical(msg) ? AlertSeverity.critical : AlertSeverity.warning);
      if (!_alerts.isClosed) _alerts.add(msg);
    }

    final arrived = s.finished;
    if (arrived || fired || DateTime.now().difference(_lastPersist).inMilliseconds > 2000) {
      _lastPersist = DateTime.now();
      _repo.applySimulation(shipment, s);
    }
    if (arrived) _repo.setStatus(shipment, ShipmentStatus.delivered);
  }

  void dispose() {
    _sub.cancel();
    _alerts.close();
    bridge.dispose();
  }
}
