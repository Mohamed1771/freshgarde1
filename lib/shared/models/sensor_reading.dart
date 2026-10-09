/// One telemetry sample from the reefer unit. In this demo all readings are mock values.
class SensorReading {
  const SensorReading({
    required this.time,
    required this.temperatureC,
    required this.humidityPct,
    required this.setpointC,
    this.outsideTempC,
  });

  final DateTime time;
  final double temperatureC;
  final double humidityPct;
  final double setpointC;
  final double? outsideTempC;

  factory SensorReading.fromJson(Map<String, dynamic> j) => SensorReading(
        time: DateTime.parse(j['time'] as String),
        temperatureC: (j['temperature_c'] as num).toDouble(),
        humidityPct: (j['humidity_pct'] as num).toDouble(),
        setpointC: (j['setpoint_c'] as num).toDouble(),
        outsideTempC: (j['outside_temp_c'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'temperature_c': temperatureC,
        'humidity_pct': humidityPct,
        'setpoint_c': setpointC,
        if (outsideTempC != null) 'outside_temp_c': outsideTempC,
      };
}
