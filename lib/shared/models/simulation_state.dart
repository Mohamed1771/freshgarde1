import 'cooling_recommendation.dart';
import 'inspection_result.dart';
import 'sensor_reading.dart';
import 'simulation_scenario.dart';

enum DecisionKind { change, hold, alert }

/// One entry of the decision layer history (every simulated scan).
class AiDecisionLog {
  const AiDecisionLog({
    required this.hour,
    required this.kind,
    required this.fromSetpoint,
    required this.toSetpoint,
    required this.reason,
    required this.confidence,
  });

  final double hour;
  final DecisionKind kind;
  final double fromSetpoint;
  final double toSetpoint;
  final String reason;
  final double confidence;
}

/// Where the produce appearance in the simulation comes from.
enum AppearanceSource {
  defaultSeed('افتراضي — بدون فحص'),
  aiInspection('مأخوذ من نتيجة الفحص');

  const AppearanceSource(this.label);
  final String label;
}

/// Full simulation state. Ripeness and deterioration are separate on purpose:
/// produce can be fully ripe and still sound, or green and already damaged.
class SimulationState {
  const SimulationState({
    required this.shipmentId,
    required this.hour,
    required this.tripHours,
    required this.playing,
    required this.coolingFailure,
    required this.smartCooling,
    required this.cargoTempC,
    required this.outsideTempC,
    required this.humidityPct,
    required this.setpointC,
    required this.ripeness,
    required this.deterioration,
    required this.qualityPct,
    required this.stage,
    required this.initialStage,
    required this.appearanceSource,
    required this.inspectionWasSimulated,
    required this.decisions,
    required this.recommendations,
    required this.alerts,
    required this.history,
    required this.predictedArrivalQualityPct,
    required this.predictedArrivalStage,
    required this.predictedArrivalRipeness,
    required this.predictedArrivalDeterioration,
    required this.scenario,
    required this.events,
    this.sceneConnected = false,
  });

  final String shipmentId;
  final double hour;
  final double tripHours;
  final bool playing;
  final bool coolingFailure;
  final bool smartCooling;
  final double cargoTempC;
  final double outsideTempC;
  final double humidityPct;
  final double setpointC;

  /// 0 (mature green) .. 1 (fully ripe). Driven by temperature (Q10 kinetics).
  final double ripeness;

  /// 0 (sound) .. 1 (fully spoiled). Driven by heat abuse, low humidity, chill and over-ripening.
  final double deterioration;
  final double qualityPct;
  final MaturityStage stage;
  final MaturityStage initialStage;
  final AppearanceSource appearanceSource;

  /// True when the seeding inspection came from the mock service (no real model).
  final bool inspectionWasSimulated;
  final List<AiDecisionLog> decisions;
  final List<CoolingRecommendation> recommendations;
  final List<String> alerts;
  final List<SensorReading> history;
  final double predictedArrivalQualityPct;
  final MaturityStage predictedArrivalStage;
  final double predictedArrivalRipeness;
  final double predictedArrivalDeterioration;

  final SimulationScenario scenario;

  /// Full scripted timeline of the scenario (past and future events).
  final List<TripEvent> events;

  List<TripEvent> get activeEvents => events.where((e) => e.activeAt(hour)).toList();

  /// True when an embedded Three.js scene is attached and receiving commands.
  final bool sceneConnected;

  double get progress => hour / tripHours;
  bool get finished => hour >= tripHours - 1e-6;

  SimulationState copyWith({bool? playing, bool? sceneConnected}) => SimulationState(
        shipmentId: shipmentId,
        hour: hour,
        tripHours: tripHours,
        playing: playing ?? this.playing,
        coolingFailure: coolingFailure,
        smartCooling: smartCooling,
        cargoTempC: cargoTempC,
        outsideTempC: outsideTempC,
        humidityPct: humidityPct,
        setpointC: setpointC,
        ripeness: ripeness,
        deterioration: deterioration,
        qualityPct: qualityPct,
        stage: stage,
        initialStage: initialStage,
        appearanceSource: appearanceSource,
        inspectionWasSimulated: inspectionWasSimulated,
        decisions: decisions,
        recommendations: recommendations,
        alerts: alerts,
        history: history,
        predictedArrivalQualityPct: predictedArrivalQualityPct,
        predictedArrivalStage: predictedArrivalStage,
        predictedArrivalRipeness: predictedArrivalRipeness,
        predictedArrivalDeterioration: predictedArrivalDeterioration,
        scenario: scenario,
        events: events,
        sceneConnected: sceneConnected ?? this.sceneConnected,
      );
}
