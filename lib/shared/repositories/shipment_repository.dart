import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/inspection_result.dart';
import '../models/sensor_reading.dart';
import '../models/shipment.dart';
import '../models/simulation_state.dart';
import 'mock_data.dart';
import 'notification_repository.dart';

/// In-memory shipment store. Changes persist for the running session.
class ShipmentRepository extends ChangeNotifier {
  ShipmentRepository(this._notifications);

  final NotificationRepository _notifications;
  final List<Shipment> _items = MockData.shipments();
  int _seq = 24030;

  List<Shipment> get all => List.unmodifiable(_items);
  List<Shipment> byStatus(ShipmentStatus s) => _items.where((e) => e.status == s).toList();
  Shipment? byId(String id) => _items.where((e) => e.id == id).firstOrNull;

  String nextId() => 'FR-${_seq++}';

  Future<Shipment> create(Shipment shipment) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _items.insert(0, shipment);
    _notifications.add(
      NotificationType.shipment,
      'تم إنشاء الشحنة ${shipment.id}',
      'شحنة ${shipment.product.name} (${shipment.quantityTons} طن) إلى ${shipment.destination} بانتظار الانطلاق.',
      shipmentId: shipment.id,
    );
    notifyListeners();
    return shipment;
  }

  void setStatus(Shipment s, ShipmentStatus status) {
    s.status = status;
    if (status == ShipmentStatus.active && s.progress == 0) s.progress = 0.02;
    if (status == ShipmentStatus.delivered) s.progress = 1;
    _notifications.add(NotificationType.shipment, 'تحديث حالة ${s.id}', 'أصبحت حالة الشحنة: ${status.label}.', shipmentId: s.id);
    notifyListeners();
  }

  /// Attaches an inspection result and re-seeds the shipment forecast from it.
  void applyInspection(Shipment s, InspectionResult r) {
    s.inspection = r;
    s.qualityPct = r.qualityScore;
    final arrival = MaturityStage.fromSimStage((r.maturityStage.simStage + 1).clamp(1, 6));
    s.forecast = QualityForecast(
      arrivalQualityPct: (r.qualityScore - 4).clamp(0, 100),
      shelfLifeDays: switch (r.maturityStage) {
        MaturityStage.matureGreen => 12,
        MaturityStage.breaker => 9,
        MaturityStage.turning => 7,
        MaturityStage.ripe => 4,
        MaturityStage.overripe => 2,
        MaturityStage.spoiled => 0,
      },
      arrivalStage: arrival,
      basis: r.isSimulated ? 'مبني على فحص محاكى' : 'مبني على فحص AI',
    );
    s.alerts.insert(
      0,
      ShipmentAlert(
        time: DateTime.now(),
        message: 'تم تطبيق نتيجة الفحص: ${r.maturityStage.label} (ثقة ${(r.confidence * 100).round()}%)${r.isSimulated ? ' — نتيجة محاكاة' : ''}',
        severity: r.maturityStage.simStage >= 5 ? AlertSeverity.warning : AlertSeverity.info,
        source: 'inspection',
      ),
    );
    _notifications.add(
      NotificationType.inspection,
      'نتيجة فحص ${s.id}',
      'المرحلة: ${r.maturityStage.label} — الجودة ${r.qualityScore.round()}%. ${r.isSimulated ? 'نتيجة توضيحية من خدمة المحاكاة.' : ''}',
      shipmentId: s.id,
    );
    notifyListeners();
  }

  /// Writes the latest simulation state back into the shipment (telemetry, quality, forecast, alerts).
  void applySimulation(Shipment s, SimulationState st) {
    s.reading = SensorReading(
      time: DateTime.now(),
      temperatureC: st.cargoTempC,
      humidityPct: st.humidityPct,
      setpointC: st.setpointC,
      outsideTempC: st.outsideTempC,
    );
    s.readings
      ..clear()
      ..addAll(st.history);
    s.coolingSetpointC = st.setpointC;
    s.smartCooling = st.smartCooling;
    s.qualityPct = st.qualityPct;
    if (s.status == ShipmentStatus.active) s.progress = st.progress.clamp(s.progress, 1.0);
    s.forecast = QualityForecast(
      arrivalQualityPct: st.predictedArrivalQualityPct,
      shelfLifeDays: (8 * (1 - st.predictedArrivalRipeness) + 3 * (1 - st.predictedArrivalDeterioration * 2)).clamp(0, 14),
      arrivalStage: st.predictedArrivalStage,
      basis: 'من المحاكاة عند الساعة ${st.hour.toStringAsFixed(1)}',
    );
    notifyListeners();
  }

  /// Adds a cooling alert raised by the simulation and pushes a notification once per message.
  void addSimulationAlert(Shipment s, String message, AlertSeverity severity) {
    if (s.alerts.any((a) => a.message == message && DateTime.now().difference(a.time).inMinutes < 10)) return;
    s.alerts.insert(0, ShipmentAlert(time: DateTime.now(), message: message, severity: severity, source: 'simulation'));
    _notifications.add(NotificationType.alert, 'تنبيه تبريد — ${s.id}', '$message (محاكاة)', shipmentId: s.id);
    notifyListeners();
  }

  void clearAlerts(Shipment s) {
    s.alerts.clear();
    notifyListeners();
  }
}
