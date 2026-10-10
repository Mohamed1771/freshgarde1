import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../shared/models/inspection_result.dart';
import '../../shared/models/shipment.dart';
import '../../shared/models/simulation_state.dart';
import 'mock_simulation_engine.dart';
import 'scene/scene_config.dart';
import 'simulation_bridge.dart';

/// [SimulationBridge] backed by [MockSimulationEngine] (the source of truth for the Flutter panels).
///
/// When a Three.js scene is attached, the timeline is mirrored to `window.FreshRouteAPI`
/// (play / seek / scenario cooling failures) so the 3D truck follows the same trip.
class MockSimulationBridge implements SimulationBridge {
  MockSimulationBridge({this.speedHoursPerSecond = 0.5, this.alertThresholdC = 3});

  final double speedHoursPerSecond;
  final double alertThresholdC;

  static const _tick = Duration(milliseconds: 200);

  final _controller = StreamController<SimulationState>.broadcast();
  late EngineParams _params;
  double _hour = 0;
  bool _playing = false;
  Timer? _timer;
  int _ticks = 0;
  SimulationState? _state;
  InspectionResult? _inspection;

  SceneChannel? _scene;
  StreamSubscription<Map<String, dynamic>>? _sceneSub;
  bool _sceneFailure = false;
  SceneTelemetry? _telemetry;

  @override
  Stream<SimulationState> get onSimulationStateChanged => _controller.stream;

  @override
  SimulationState get state => _state!;

  @override
  SceneTelemetry? get sceneTelemetry => _telemetry;

  double get hour => _hour;
  bool get playing => _playing;

  // ---------------------------------------------------------------- commands

  @override
  Future<void> initializeShipment(Shipment s) async {
    _inspection = s.inspection;
    _params = EngineParams(
      shipmentId: s.id,
      product: s.product,
      baseSetpointC: s.coolingSetpointC,
      initialStage: s.initialStage,
      extraDeterioration: s.inspection?.defectDeterioration ?? 0,
      appearanceSource: s.inspection == null ? AppearanceSource.defaultSeed : AppearanceSource.aiInspection,
      inspectionWasSimulated: s.inspection?.isSimulated ?? false,
      departure: s.departure,
      scenario: s.scenario,
      alertThresholdC: alertThresholdC,
    );
    _hour = 0;
    _setPlaying(false);
    _emit();
    await _syncScene();
  }

  @override
  Future<void> setProductFromAI(InspectionResult result) async {
    _inspection = result;
    _params = _params.withInspection(result);
    _emit();
    await _applyPredictionToScene();
  }

  @override
  Future<void> start() async {
    if (_hour >= MockSimulationEngine.tripHours - 1e-6) return;
    _setPlaying(true);
    _emit();
    await _js('FreshRouteAPI.setSpeed($speedHoursPerSecond);FreshRouteAPI.play()');
  }

  @override
  Future<void> pause() async {
    _setPlaying(false);
    _emit();
    await _js('FreshRouteAPI.seek(${_hour.toStringAsFixed(2)})');
  }

  @override
  Future<void> reset() async {
    _hour = 0;
    _setPlaying(false);
    _emit();
    await _syncScene();
  }

  @override
  Future<void> setTime(double hour) async {
    _hour = hour.clamp(0, MockSimulationEngine.tripHours);
    _emit();
    await _syncScene();
  }

  @override
  Future<void> inspectCrate(int crate) => _js('FreshRouteAPI.inspect($crate)');

  // ---------------------------------------------------------------- scene

  @override
  void attachScene(SceneChannel channel) {
    _sceneSub?.cancel();
    _scene = channel;
    _sceneSub = channel.messages.listen((m) {
      final tel = SceneTelemetry.fromMessage(m);
      if (tel != null) {
        _telemetry = tel;
        _emit();
      }
    });
    _syncScene();
  }

  @override
  void detachScene() {
    _sceneSub?.cancel();
    _sceneSub = null;
    _scene = null;
    _telemetry = null;
  }

  /// Brings the scene to the bridge state: reset, AI-seeded crate, current time, failure, play.
  Future<void> _syncScene() async {
    if (_scene == null) return;
    _sceneFailure = false;
    await _scene?.run(SceneConfig.embedJs).catchError((Object _) {});
    await _js('FreshRouteAPI.reset();FreshRouteAPI.setSpeed($speedHoursPerSecond);FreshRouteAPI.setAI(true)');
    await _applyPredictionToScene();
    if (_hour > 0) await _js('FreshRouteAPI.seek(${_hour.toStringAsFixed(2)})');
    await _mirrorFailure();
    if (_playing) await _js('FreshRouteAPI.play()');
  }

  /// Forwards scenario cooling failures to the scene's own physics.
  Future<void> _mirrorFailure() async {
    final failure = _state?.coolingFailure ?? false;
    if (_scene == null || failure == _sceneFailure) return;
    _sceneFailure = failure;
    await _js('FreshRouteAPI.toggleFailure()');
  }

  /// Crate 1 shows the inspected produce; the other crates keep the scene's own ripening model.
  Future<void> _applyPredictionToScene() async {
    final r = _inspection;
    if (r == null) return;
    final source = jsonEncode(r.isSimulated ? 'FreshGarde mock inspection (simulated)' : 'FreshGarde (${r.modelVersion})');
    await _js('FreshRouteAPI.applyPrediction(0,{stage:${r.maturityStage.simStage},confidence:${r.confidence},source:$source})');
  }

  Future<void> _js(String code) async {
    final s = _scene;
    if (s == null) return;
    try {
      await s.run('if(window.FreshRouteAPI){$code}');
    } catch (e) {
      debugPrint('Scene command failed: $e');
    }
  }

  // ---------------------------------------------------------------- internals

  void _setPlaying(bool v) {
    _playing = v;
    _timer?.cancel();
    _timer = null;
    if (!v) return;
    _timer = Timer.periodic(_tick, (_) {
      _hour += speedHoursPerSecond * _tick.inMilliseconds / 1000;
      if (_hour >= MockSimulationEngine.tripHours) {
        _hour = MockSimulationEngine.tripHours;
        _setPlaying(false);
      }
      _emit();
      _mirrorFailure();
      // The scene keeps its own clock (and browsers throttle hidden frames): resync every ~6 s.
      if (++_ticks % 30 == 0 && _playing) _js('FreshRouteAPI.seek(${_hour.toStringAsFixed(2)});FreshRouteAPI.play()');
    });
  }

  void _emit() {
    final s = MockSimulationEngine.compute(_params, _hour, playing: _playing);
    _state = s.copyWith(sceneConnected: _scene != null);
    if (!_controller.isClosed) _controller.add(_state!);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sceneSub?.cancel();
    _controller.close();
  }
}
