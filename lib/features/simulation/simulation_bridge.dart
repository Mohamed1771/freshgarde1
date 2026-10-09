import 'dart:async';

import '../../shared/models/inspection_result.dart';
import '../../shared/models/shipment.dart';
import '../../shared/models/simulation_state.dart';

/// Contract between the Flutter UI and a refrigerated-truck simulation.
///
/// The trip runs on its own from a fixed scenario timeline (no user controls). Commands mirror the
/// existing Three.js scene API (`window.FreshRouteAPI`): `initializeShipment`, `setProductFromAI`,
/// `start`, `pause`, `reset`, `setTime`, plus the [onSimulationStateChanged] stream. Cooling failures
/// scripted by the scenario are forwarded to the scene automatically.
abstract interface class SimulationBridge {
  /// Emits a new [SimulationState] whenever the simulation changes.
  Stream<SimulationState> get onSimulationStateChanged;

  SimulationState get state;

  /// Last telemetry reported by the embedded 3D scene, if one is attached.
  SceneTelemetry? get sceneTelemetry;

  Future<void> initializeShipment(Shipment shipment);

  /// Seeds the produce condition from an inspection. Real inference and simulated
  /// appearance stay distinct: the result only sets the *starting* stage.
  Future<void> setProductFromAI(InspectionResult result);

  Future<void> start();
  Future<void> pause();
  Future<void> reset();

  /// Jumps to a simulated hour (0..48).
  Future<void> setTime(double hour);

  /// Opens the close-up crate inspector inside the 3D scene (no-op without a scene).
  Future<void> inspectCrate(int crate);

  /// Connects / disconnects an embedded scene (WebView or iframe).
  void attachScene(SceneChannel channel);
  void detachScene();

  void dispose();
}

/// Low-level channel to the embedded Three.js page. Implemented per platform
/// (webview_flutter on Android/iOS, iframe on Flutter Web).
abstract interface class SceneChannel {
  /// Evaluates JavaScript inside the scene page.
  Future<void> run(String js);

  /// JSON messages posted by the page through `window.FR.postMessage`.
  Stream<Map<String, dynamic>> get messages;
}

/// Subset of the scene's `snapshot` message shown in the viewport overlay.
class SceneTelemetry {
  const SceneTelemetry({required this.hour, required this.cargoTempC, required this.setpointC, required this.failure, required this.playing});

  final double hour;
  final double cargoTempC;
  final double setpointC;
  final bool failure;
  final bool playing;

  static SceneTelemetry? fromMessage(Map<String, dynamic> m) {
    if (m['type'] != 'snapshot') return null;
    double d(Object? v) => (v as num?)?.toDouble() ?? 0;
    return SceneTelemetry(
      hour: d(m['t']),
      cargoTempC: d(m['cargo']),
      setpointC: d(m['setpoint']),
      failure: m['failure'] == true,
      playing: m['playing'] == true,
    );
  }
}
