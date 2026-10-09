import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Minimal line chart for telemetry (no chart package needed).
/// Draws [values] with an optional dashed [reference] line (e.g. the setpoint).
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.reference, this.color = AppColors.primary, this.height = 90, this.minSpan = 4});
  final List<double> values;
  final double? reference;
  final Color color;
  final double height;
  final double minSpan;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: values.length < 2
            ? Center(child: Text('لا توجد بيانات كافية', style: Theme.of(context).textTheme.bodySmall))
            : CustomPaint(painter: _SparkPainter(values, reference, color, minSpan, Directionality.of(context) == TextDirection.rtl)),
      );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.v, this.ref, this.color, this.minSpan, this.rtl);
  final List<double> v;
  final double? ref;
  final Color color;
  final double minSpan;

  /// Time flows with the reading direction: right-to-left in Arabic.
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    var lo = v.reduce((a, b) => a < b ? a : b);
    var hi = v.reduce((a, b) => a > b ? a : b);
    if (ref != null) {
      lo = lo < ref! ? lo : ref!;
      hi = hi > ref! ? hi : ref!;
    }
    if (hi - lo < minSpan) {
      final mid = (hi + lo) / 2;
      lo = mid - minSpan / 2;
      hi = mid + minSpan / 2;
    }
    double y(double x) => size.height - 4 - (x - lo) / (hi - lo) * (size.height - 8);
    double x(int i) {
      final f = i / (v.length - 1) * size.width;
      return rtl ? size.width - f : f;
    }

    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final gy = i / 3 * size.height;
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), grid);
    }

    if (ref != null) {
      final p = Paint()
        ..color = AppColors.textMuted
        ..strokeWidth = 1.2;
      for (var dx = 0.0; dx < size.width; dx += 8) {
        canvas.drawLine(Offset(dx, y(ref!)), Offset(dx + 4, y(ref!)), p);
      }
    }

    final path = Path()..moveTo(x(0), y(v[0]));
    for (var i = 1; i < v.length; i++) {
      path.lineTo(x(i), y(v[i]));
    }
    final fill = Path.from(path)
      ..lineTo(x(v.length - 1), size.height)
      ..lineTo(x(0), size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(Offset(x(v.length - 1), y(v.last)), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.v != v || old.ref != ref || old.rtl != rtl;
}
