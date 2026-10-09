import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/models/product.dart';
import '../theme/app_colors.dart';

/// Product image placeholder (gradient + emoji). Swap for network/asset photos when available.
class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.product, this.size = 64, this.radius = 12});
  final Product product;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [product.color.withValues(alpha: 0.18), product.color.withValues(alpha: 0.42)],
          ),
        ),
        alignment: Alignment.center,
        child: Text(product.emoji, style: TextStyle(fontSize: size * 0.48)),
      );
}

/// Wide banner version for detail screens.
class ProductBanner extends StatelessWidget {
  const ProductBanner({super.key, required this.product, this.height = 190});
  final Product product;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [product.color.withValues(alpha: 0.25), AppColors.ice]),
        ),
        alignment: Alignment.center,
        child: Text(product.emoji, style: TextStyle(fontSize: height * 0.45)),
      );
}

/// Simulated produce appearance. Colour follows ripeness (green → red);
/// spots, darkening and shrinking follow deterioration. This is a visualisation, not AI inference.
class ProduceAppearance extends StatelessWidget {
  const ProduceAppearance({super.key, required this.ripeness, required this.deterioration, this.height = 120});
  final double ripeness;
  final double deterioration;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _ProducePainter(ripeness.clamp(0, 1), deterioration.clamp(0, 1))),
      );
}

class _ProducePainter extends CustomPainter {
  _ProducePainter(this.r, this.d);
  final double r;
  final double d;

  static const _ramp = [Color(0xFF6AA843), Color(0xFFB4B44C), Color(0xFFEA8C2C), Color(0xFFD33A22), Color(0xFFA42A1A)];

  Color _base() {
    final x = r * (_ramp.length - 1);
    final i = x.floor().clamp(0, _ramp.length - 2);
    return Color.lerp(_ramp[i], _ramp[i + 1], x - i)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFC79B63);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)), bg);
    final slat = Paint()..color = const Color(0xFFB98A55);
    for (var y = 0.0; y < size.height; y += 18) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 6), slat);
    }

    final base = Color.lerp(_base(), const Color(0xFF4A3424), d * 0.75)!;
    final rnd = math.Random(11);
    final count = (size.width / 46).floor().clamp(5, 14);
    final radius = size.height * 0.26 * (1 - 0.12 * d);
    for (var row = 0; row < 2; row++) {
      for (var i = 0; i < count; i++) {
        final cx = (i + 0.5 + (row == 1 ? 0.5 : 0)) * size.width / (count + 0.5);
        final cy = size.height * (row == 0 ? 0.34 : 0.7) + (rnd.nextDouble() - 0.5) * 6;
        final c = Offset(cx, cy);
        final jitter = (rnd.nextDouble() - 0.5) * 0.12;
        canvas.drawCircle(c.translate(2, 3), radius, Paint()..color = Colors.black.withValues(alpha: 0.15));
        canvas.drawCircle(c, radius, Paint()..color = Color.lerp(base, Colors.black, jitter.abs())!);
        canvas.drawCircle(c.translate(-radius * 0.35, -radius * 0.35), radius * 0.28,
            Paint()..color = Colors.white.withValues(alpha: 0.28 * (1 - d)));
        // Calyx
        canvas.drawCircle(c.translate(0, -radius * 0.85), radius * 0.18, Paint()..color = Color.lerp(const Color(0xFF3F7D32), const Color(0xFF5A4A2A), d)!);
        // Decay spots
        final spots = (d * 6).round();
        for (var s = 0; s < spots; s++) {
          final a = rnd.nextDouble() * math.pi * 2;
          final dist = rnd.nextDouble() * radius * 0.6;
          canvas.drawCircle(c + Offset(math.cos(a) * dist, math.sin(a) * dist), radius * (0.1 + 0.15 * d),
              Paint()..color = const Color(0xFF2E2117).withValues(alpha: 0.75));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ProducePainter old) => old.r != r || old.d != d;
}
