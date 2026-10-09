import 'dart:math' as math;

import '../../core/utils/formatters.dart';
import '../../shared/models/cooling_recommendation.dart';
import '../../shared/models/inspection_result.dart';
import '../../shared/models/product.dart';
import '../../shared/models/sensor_reading.dart';
import '../../shared/models/simulation_scenario.dart';
import '../../shared/models/simulation_state.dart';

class EngineParams {
  EngineParams({
    required this.shipmentId,
    required this.product,
    required this.baseSetpointC,
    required this.initialStage,
    required this.extraDeterioration,
    required this.appearanceSource,
    required this.inspectionWasSimulated,
    required this.departure,
    required this.scenario,
    this.alertThresholdC = 3,
  })  : seed = SimulationScenario.seedOf(shipmentId),
        events = scenario.timeline(SimulationScenario.seedOf(shipmentId));

  final String shipmentId;
  final Product product;
  final double baseSetpointC;
  final MaturityStage initialStage;
  final double extraDeterioration;
  final AppearanceSource appearanceSource;
  final bool inspectionWasSimulated;
  final DateTime departure;
  final SimulationScenario scenario;
  final double alertThresholdC;
  final int seed;
  final List<TripEvent> events;

  EngineParams withInspection(InspectionResult r) => EngineParams(
        shipmentId: shipmentId,
        product: product,
        baseSetpointC: baseSetpointC,
        initialStage: r.maturityStage,
        extraDeterioration: r.defectDeterioration,
        appearanceSource: AppearanceSource.aiInspection,
        inspectionWasSimulated: r.isSimulated,
        departure: departure,
        scenario: scenario,
        alertThresholdC: alertThresholdC,
      );
}

/// Deterministic, illustrative cold-chain model (pure Dart, no randomness).
///
/// * Trip conditions come from a fixed [SimulationScenario] timeline (cooling failure, door openings,
///   heat waves, power drops, humidifier failure), slightly shifted per shipment.
/// * Ripeness and deterioration are separate state variables.
/// * A rule-based decision layer re-evaluates the setpoint every 3 h (always on).
///
/// Kinetics are for demonstration only and are not validated science.
class MockSimulationEngine {
  static const tripHours = 48.0;
  static const _dt = 0.1;
  static const _scanEvery = 3.0;

  static double outsideTemp(EngineParams p, double h) {
    final amp = 6 + (p.seed % 4); // 6..9 °C daily swing
    return 26 + (p.seed % 3) + amp * math.sin(2 * math.pi * (h - 9) / 24) + conditionsAt(p.events, h).ambientOffsetC;
  }

  static MaturityStage stageOf(double r, double d) {
    if (d >= 0.45) return MaturityStage.spoiled;
    if (d >= 0.22 || r >= 0.985) return MaturityStage.overripe;
    if (r < 0.15) return MaturityStage.matureGreen;
    if (r < 0.38) return MaturityStage.breaker;
    if (r < 0.65) return MaturityStage.turning;
    return MaturityStage.ripe;
  }

  static double qualityOf(double r, double d) =>
      (100 * (1 - d * 1.15) - math.max(0, r - 0.9) * 40).clamp(0, 100).toDouble();

  /// Runs the model from hour 0 to [hour].
  static SimulationState compute(EngineParams p, double hour, {bool playing = false}) {
    final opt = p.product.optimalTempC;
    final seed = p.initialStage.seed;
    var r = seed.$1;
    var d = (seed.$2 + p.extraDeterioration).clamp(0.0, 1.0);
    var temp = p.baseSetpointC + 1.5;
    var hum = p.product.optimalHumidity - 2;
    var set = p.baseSetpointC;
    var nextScan = 0.0;
    var nextHist = 0.0;
    final decisions = <AiDecisionLog>[];
    final history = <SensorReading>[];
    var t = 0.0;
    final end = hour.clamp(0.0, tripHours);

    while (true) {
      final c = conditionsAt(p.events, t);
      if (t >= nextHist - 1e-9) {
        history.add(SensorReading(
          time: p.departure.add(Duration(minutes: (t * 60).round())),
          temperatureC: double.parse(temp.toStringAsFixed(2)),
          humidityPct: double.parse(hum.toStringAsFixed(1)),
          setpointC: set,
          outsideTempC: double.parse(outsideTemp(p, t).toStringAsFixed(1)),
        ));
        nextHist += 0.5;
      }
      if (t >= nextScan - 1e-9) {
        final log = _decide(p, t, r, d, temp, set, c);
        decisions.add(log);
        set = log.toSetpoint;
        nextScan += _scanEvery;
      }
      if (t >= end - 1e-9) break;

      final step = math.min(_dt, end - t);
      final out = outsideTemp(p, t);
      final leak = 0.015 + (c.doorOpen ? 0.35 : 0) + (1 - c.coolingCapacity) * 0.14;
      temp += ((set - temp) * 0.9 * c.coolingCapacity + (out - temp) * leak) * step;
      final humTarget = c.coolingFailure
          ? 72.0
          : c.doorOpen
              ? 65.0
              : (c.humidifierOk ? p.product.optimalHumidity : p.product.optimalHumidity - 16);
      hum += (humTarget - hum) * (c.doorOpen ? 1.2 : 0.25) * step;

      final q = math.pow(2.4, (temp - opt) / 10).toDouble();
      if (r < 1) r = math.min(1, r + 0.011 * q * step);
      final heat = math.max(0, temp - (opt + 6)) * 0.0016;
      final chill = opt >= 7 ? math.max(0, (opt - 4) - temp) * 0.002 : 0.0;
      final dry = hum < 80 ? (80 - hum) * 0.00025 : 0.0;
      final over = r >= 0.98 ? 0.0015 : 0.0;
      d = math.min(1, d + (0.0012 * q + heat + chill + dry + over) * step);
      t += step;
    }

    final cNow = conditionsAt(p.events, end);
    final stage = stageOf(r, d);
    final quality = qualityOf(r, d);
    final alerts = <String>[
      if (cNow.coolingFailure) 'عطل في وحدة التبريد — التبريد متوقف',
      if (!cNow.coolingFailure && cNow.coolingCapacity < 1) 'انخفاض قدرة وحدة التبريد إلى ${(cNow.coolingCapacity * 100).round()}%',
      if (cNow.doorOpen) 'باب الحاوية مفتوح',
      if (temp - set > p.alertThresholdC) 'حرارة الحمولة أعلى من نقطة الضبط بـ ${Fmt.temp(temp - set)}',
      if (hum < 82) 'انخفاض الرطوبة إلى ${hum.toStringAsFixed(0)}%',
      if (d >= 0.22) 'تدهور ملحوظ في جودة الحمولة',
    ];

    double? arrQ;
    var arrR = r, arrD = d;
    if (end < tripHours - 1e-6) {
      final arrival = compute(p, tripHours);
      arrQ = arrival.qualityPct;
      arrR = arrival.ripeness;
      arrD = arrival.deterioration;
    }

    return SimulationState(
      shipmentId: p.shipmentId,
      hour: end,
      tripHours: tripHours,
      playing: playing,
      coolingFailure: cNow.coolingFailure,
      smartCooling: true,
      cargoTempC: temp,
      outsideTempC: outsideTemp(p, end),
      humidityPct: hum,
      setpointC: set,
      ripeness: r,
      deterioration: d,
      qualityPct: quality,
      stage: stage,
      initialStage: p.initialStage,
      appearanceSource: p.appearanceSource,
      inspectionWasSimulated: p.inspectionWasSimulated,
      decisions: decisions,
      recommendations: _recommend(p, stage, r, hum, set, cNow, tripHours - end),
      alerts: alerts,
      history: history,
      predictedArrivalQualityPct: arrQ ?? quality,
      predictedArrivalStage: stageOf(arrR, arrD),
      predictedArrivalRipeness: arrR,
      predictedArrivalDeterioration: arrD,
      scenario: p.scenario,
      events: p.events,
    );
  }

  static double _target(EngineParams p, MaturityStage s, double hoursLeft, double r) {
    final opt = p.product.optimalTempC;
    var target = switch (s) {
      MaturityStage.matureGreen || MaturityStage.breaker => opt + 1.0,
      MaturityStage.turning => opt,
      MaturityStage.ripe => opt - 1.0,
      MaturityStage.overripe || MaturityStage.spoiled => opt - 1.5,
    };
    if (hoursLeft < 8 && r > 0.7) target = math.min(target, opt - 1);
    return target.clamp(math.max(0.5, opt - 2.5), opt + 1.5).toDouble();
  }

  static AiDecisionLog _decide(EngineParams p, double t, double r, double d, double temp, double set, TripConditions c) {
    final s = stageOf(r, d);
    final conf = double.parse((0.82 + 0.14 * (1 - d) - (c.coolingCapacity < 1 ? 0.05 : 0)).clamp(0.5, 0.97).toStringAsFixed(2));
    if (c.coolingFailure && temp - set > 1.5) {
      return AiDecisionLog(
        hour: t,
        kind: DecisionKind.alert,
        fromSetpoint: set,
        toSetpoint: set,
        confidence: conf,
        reason: 'الحرارة ${Fmt.temp(temp)} رغم نقطة ضبط ${Fmt.temp(set)} — يُشتبه بعطل في التبريد. يُوصى بالإصلاح الفوري وإعطاء الأولوية لتفريغ الحمولة.',
      );
    }
    var target = _target(p, s, tripHours - t, r);
    var reasonSuffix = '';
    if (c.coolingCapacity < 1 && temp - set > 1) {
      target = math.max(p.product.optimalTempC - 2.5, set - 1); // compensate for reduced capacity
      reasonSuffix = ' (تعويض عن انخفاض قدرة التبريد)';
    }
    final next = set + (target - set).clamp(-1.0, 1.0);
    final rounded = (next * 2).round() / 2;
    if ((rounded - set).abs() < 0.25) {
      return AiDecisionLog(hour: t, kind: DecisionKind.hold, fromSetpoint: set, toSetpoint: set, confidence: conf,
          reason: 'المنتج في مرحلة "${s.label}" والظروف مستقرة — إبقاء ${Fmt.temp(set)}.');
    }
    final up = rounded > set;
    return AiDecisionLog(
      hour: t,
      kind: DecisionKind.change,
      fromSetpoint: set,
      toSetpoint: rounded,
      confidence: conf,
      reason: up
          ? 'المنتج "${s.label}" وحساس للبرودة — رفع الحرارة إلى ${Fmt.temp(rounded)} يقلّل ضرر البرد ويوفّر طاقة.'
          : 'المنتج "${s.label}" — خفض الحرارة إلى ${Fmt.temp(rounded)} لإبطاء النضج حتى الوصول$reasonSuffix.',
    );
  }

  static List<CoolingRecommendation> _recommend(
      EngineParams p, MaturityStage s, double r, double hum, double set, TripConditions c, double hoursLeft) {
    final recs = <CoolingRecommendation>[];
    if (c.coolingFailure) {
      recs
        ..add(const CoolingRecommendation(
          title: 'إصلاح وحدة التبريد فورًا',
          detail: 'تواصل مع السائق لفحص الضاغط ومصدر الطاقة. كل ساعة دون تبريد تسرّع التلف بشكل كبير.',
          priority: RecommendationPriority.urgent,
        ))
        ..add(const CoolingRecommendation(
          title: 'التوجيه إلى أقرب مستودع مبرّد',
          detail: 'إذا تعذّر الإصلاح خلال ساعتين، انقل الحمولة أو أعطِ الأولوية لبيع الصناديق الأكثر نضجًا.',
          priority: RecommendationPriority.urgent,
        ));
    } else if (c.coolingCapacity < 1) {
      recs.add(CoolingRecommendation(
        title: 'فحص مصدر طاقة وحدة التبريد',
        detail: 'القدرة الحالية ${(c.coolingCapacity * 100).round()}% فقط. تحقق من المولّد ووصلات الكهرباء.',
        priority: RecommendationPriority.urgent,
      ));
    }
    if (c.doorOpen) {
      recs.add(const CoolingRecommendation(
        title: 'إغلاق باب الحاوية',
        detail: 'كل دقيقة والباب مفتوح ترفع حرارة الحمولة وتخفض الرطوبة بسرعة.',
        priority: RecommendationPriority.urgent,
      ));
    }
    if (c.ambientOffsetC > 0) {
      recs.add(const CoolingRecommendation(
        title: 'تقليل التعرّض للحر',
        detail: 'موجة حر على المسار: تجنّب التوقف تحت الشمس وقلّل فتح الأبواب.',
        priority: RecommendationPriority.advisory,
      ));
    }
    if (!c.humidifierOk) {
      recs.add(const CoolingRecommendation(
        title: 'إصلاح نظام الترطيب',
        detail: 'غطِّ الصناديق بأغطية رطبة مؤقتًا لتقليل فقدان الوزن والذبول.',
        priority: RecommendationPriority.advisory,
      ));
    } else if (hum < 85 && !c.doorOpen) {
      recs.add(CoolingRecommendation(
        title: 'رفع الرطوبة',
        detail: 'الرطوبة ${hum.toStringAsFixed(0)}% أقل من الموصى (${p.product.optimalHumidity.toStringAsFixed(0)}%).',
        priority: RecommendationPriority.advisory,
      ));
    }
    if (r > 0.85) {
      recs.add(const CoolingRecommendation(
        title: 'أولوية التسليم السريع',
        detail: 'المنتج قريب من النضج الكامل؛ يُنصح بتسريع التفريغ أو التوجيه لسوق قريب.',
        priority: RecommendationPriority.advisory,
      ));
    }
    if (recs.isEmpty) {
      recs.add(CoolingRecommendation(
        title: 'الظروف مناسبة',
        detail: 'حافظ على ${Fmt.temp(set)} ورطوبة ${p.product.optimalHumidity.toStringAsFixed(0)}%.',
        priority: RecommendationPriority.info,
        targetSetpointC: set,
      ));
    }
    return recs;
  }
}
