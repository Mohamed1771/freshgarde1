import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'inspection_result.dart';
import 'product.dart';
import 'sensor_reading.dart';
import 'simulation_scenario.dart';

enum ShipmentStatus {
  active('نشطة', Icons.local_shipping_outlined),
  pending('قيد الانتظار', Icons.schedule),
  delivered('تم التسليم', Icons.task_alt),
  archived('مؤرشفة', Icons.inventory_2_outlined);

  const ShipmentStatus(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum CargoCondition {
  excellent('ممتازة', AppColors.success),
  good('جيدة', Color(0xFF3C9D5D)),
  fair('مقبولة', AppColors.warning),
  atRisk('معرّضة للخطر', Color(0xFFE0711B)),
  critical('حرجة', AppColors.danger);

  const CargoCondition(this.label, this.color);
  final String label;
  final Color color;

  static CargoCondition fromQuality(double q) => q >= 90
      ? excellent
      : q >= 78
          ? good
          : q >= 65
              ? fair
              : q >= 50
                  ? atRisk
                  : critical;
}

enum AlertSeverity {
  info('معلومة', AppColors.info, Icons.info_outline),
  warning('تحذير', AppColors.warning, Icons.warning_amber_rounded),
  critical('حرج', AppColors.danger, Icons.error_outline);

  const AlertSeverity(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

class ShipmentAlert {
  const ShipmentAlert({required this.time, required this.message, required this.severity, this.source = 'mock'});
  final DateTime time;
  final String message;
  final AlertSeverity severity;

  /// Where the alert came from: `mock`, `simulation` or `sensor`.
  final String source;
}

class QualityForecast {
  const QualityForecast({
    required this.arrivalQualityPct,
    required this.shelfLifeDays,
    required this.arrivalStage,
    required this.basis,
  });

  final double arrivalQualityPct;
  final double shelfLifeDays;
  final MaturityStage arrivalStage;

  /// Human-readable origin of the forecast (e.g. "تقدير تجريبي" or "محاكاة").
  final String basis;
}

class Shipment {
  Shipment({
    required this.id,
    required this.exporterName,
    required this.exporterCompany,
    required this.importerName,
    required this.importerCompany,
    required this.importerCountry,
    required this.product,
    required this.variety,
    required this.quantityTons,
    required this.packaging,
    required this.origin,
    required this.destination,
    required this.departure,
    required this.eta,
    required this.status,
    required this.truckType,
    required this.truckPlate,
    required this.driverName,
    required this.coolingSetpointC,
    required this.smartCooling,
    required this.reading,
    required this.qualityPct,
    required this.forecast,
    this.inspection,
    this.progress = 0,
    SimulationScenario? scenario,
    List<ShipmentAlert>? alerts,
    List<SensorReading>? readings,
    DateTime? createdAt,
  })  : scenario = scenario ?? SimulationScenario.forId(id),
        alerts = alerts ?? [],
        readings = readings ?? [reading],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String exporterName;
  final String exporterCompany;
  final String importerName;
  final String importerCompany;
  final String importerCountry;
  final Product product;
  final String variety;
  final double quantityTons;
  final String packaging;
  final String origin;
  final String destination;
  final DateTime departure;
  final DateTime eta;
  ShipmentStatus status;
  final String truckType;
  final String truckPlate;
  final String driverName;
  double coolingSetpointC;
  bool smartCooling;
  SensorReading reading;
  double qualityPct;
  QualityForecast forecast;
  InspectionResult? inspection;
  double progress;

  /// Scripted trip scenario used by the live simulation (fixed per shipment).
  final SimulationScenario scenario;
  final List<ShipmentAlert> alerts;
  final List<SensorReading> readings;
  final DateTime createdAt;

  CargoCondition get condition => CargoCondition.fromQuality(qualityPct);

  /// Produce stage used to seed the simulation: the AI inspection when available, a default otherwise.
  MaturityStage get initialStage => inspection?.maturityStage ?? MaturityStage.breaker;

  bool get hasUnresolvedCritical => alerts.any((a) => a.severity == AlertSeverity.critical);
  String get route => '$origin ← $destination';
  Duration get transitDuration => eta.difference(departure);
}
