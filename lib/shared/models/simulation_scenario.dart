import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Kinds of things that can happen during a trip.
enum TripEventKind {
  door('فتح الباب', Icons.sensor_door_outlined, AppColors.warning),
  coolingFailure('عطل تبريد', Icons.power_off_outlined, AppColors.danger),
  heat('موجة حر', Icons.wb_sunny_outlined, Color(0xFFE0711B)),
  borderWait('انتظار حدودي', Icons.hourglass_bottom, AppColors.sky),
  power('تذبذب طاقة', Icons.bolt_outlined, AppColors.warning),
  humidity('تعطّل الترطيب', Icons.water_drop_outlined, AppColors.sky);

  const TripEventKind(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// One scripted event on the 0–48 h timeline.
class TripEvent {
  const TripEvent(this.kind, this.start, this.end, this.description);
  final TripEventKind kind;
  final double start;
  final double end;
  final String description;

  bool activeAt(double h) => h >= start - 1e-9 && h < end - 1e-9;
}

/// Physical conditions applied by the engine at a given hour.
class TripConditions {
  const TripConditions({this.coolingCapacity = 1, this.ambientOffsetC = 0, this.doorOpen = false, this.humidifierOk = true});

  /// 1 = normal, 0 = cooling unit down.
  final double coolingCapacity;
  final double ambientOffsetC;
  final bool doorOpen;
  final bool humidifierOk;

  bool get coolingFailure => coolingCapacity <= 0;
}

/// Fixed simulation scenarios. Each shipment gets one (stable per shipment), so the data that a future
/// model learns from or is evaluated on is not always the same trip.
enum SimulationScenario {
  stable('رحلة مستقرة', 'ظروف طبيعية مع فتح قصير للباب عند التفتيش الجمركي.'),
  coolingFailure('عطل تبريد مؤقت', 'يتعطل ضاغط التبريد منتصف الرحلة ثم يُصلح بعد عدة ساعات.'),
  heatwaveBorder('موجة حر وتأخير حدودي', 'حرارة خارجية مرتفعة وانتظار طويل على المعبر مع فتح الباب.'),
  powerFluctuation('تذبذب طاقة الوحدة', 'انخفاض متكرر في قدرة وحدة التبريد بسبب مشاكل الطاقة.'),
  humidityLoss('انخفاض الرطوبة', 'يتعطل نظام الترطيب وتجف الحمولة تدريجيًا.'),
  lateFailure('عطل قرب الوصول', 'عطل تبريد غير مُصلَح في الساعات الأخيرة من الرحلة.');

  const SimulationScenario(this.label, this.description);
  final String label;
  final String description;

  /// Deterministic pick from the numeric part of a shipment ID.
  static SimulationScenario forId(String id) => values[_seedOf(id) % values.length];

  /// Builds the event timeline. [seed] shifts event times by up to ±2 h so that two shipments
  /// with the same scenario are similar but not identical.
  List<TripEvent> timeline(int seed) {
    final j = (seed % 5) - 2.0;
    return switch (this) {
      stable => [
          TripEvent(TripEventKind.door, 14 + j, 14.4 + j, 'فتح الباب للتفتيش الجمركي'),
        ],
      coolingFailure => [
          TripEvent(TripEventKind.door, 14 + j, 14.4 + j, 'فتح الباب للتفتيش الجمركي'),
          TripEvent(TripEventKind.coolingFailure, 26 + j, 31 + j, 'عطل في ضاغط وحدة التبريد ثم إصلاحه'),
        ],
      heatwaveBorder => [
          TripEvent(TripEventKind.heat, 10, 30, 'موجة حر (+8°C على الحرارة الخارجية)'),
          TripEvent(TripEventKind.borderWait, 16 + j, 22 + j, 'انتظار على المعبر والمحرك على الوضع الخامل'),
          TripEvent(TripEventKind.door, 18 + j, 18.5 + j, 'فتح الباب للتفتيش'),
        ],
      powerFluctuation => [
          TripEvent(TripEventKind.power, 8 + j, 14 + j, 'انخفاض قدرة وحدة التبريد إلى 35%'),
          TripEvent(TripEventKind.power, 33 + j, 37 + j, 'تذبذب طاقة ثانٍ'),
        ],
      humidityLoss => [
          TripEvent(TripEventKind.humidity, 12 + j, 40, 'توقف نظام الترطيب'),
        ],
      lateFailure => [
          TripEvent(TripEventKind.door, 20 + j, 20.4 + j, 'فتح الباب للتفتيش'),
          TripEvent(TripEventKind.coolingFailure, 39 + j, 48, 'عطل تبريد غير مُصلَح قبل الوصول'),
        ],
    };
  }

  static int seedOf(String id) => _seedOf(id);

  static int _seedOf(String id) {
    final digits = int.tryParse(id.replaceAll(RegExp(r'\D'), ''));
    if (digits != null) return digits;
    return id.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x7fffffff);
  }
}

TripConditions conditionsAt(List<TripEvent> events, double h) {
  var cap = 1.0, ambient = 0.0, door = false, humid = true;
  for (final e in events) {
    if (!e.activeAt(h)) continue;
    switch (e.kind) {
      case TripEventKind.coolingFailure:
        cap = 0;
      case TripEventKind.power:
        cap = cap < 0.35 ? cap : 0.35;
      case TripEventKind.borderWait:
        cap = cap < 0.75 ? cap : 0.75;
      case TripEventKind.heat:
        ambient += 8;
      case TripEventKind.door:
        door = true;
      case TripEventKind.humidity:
        humid = false;
    }
  }
  return TripConditions(coolingCapacity: cap, ambientOffsetC: ambient, doorOpen: door, humidifierOk: humid);
}
