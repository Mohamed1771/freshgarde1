import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 72, this.light = false});
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.sky], begin: Alignment.topRight, end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(size * 0.28),
          border: light ? Border.all(color: AppColors.white.withValues(alpha: 0.5), width: 2) : null,
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(Icons.local_shipping_rounded, color: AppColors.white, size: size * 0.52),
          PositionedDirectional(
            top: size * 0.12,
            end: size * 0.12,
            child: Icon(Icons.ac_unit, color: AppColors.white, size: size * 0.24),
          ),
        ]),
      );
}

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.light = false});
  final bool light;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = light ? AppColors.white : AppColors.navy;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('FreshRoute AI', style: t.headlineMedium?.copyWith(color: c), textDirection: TextDirection.ltr),
      Text('منصة التجارة الزراعية والنقل المبرّد الذكي', style: t.bodyMedium?.copyWith(color: c.withValues(alpha: 0.75))),
    ]);
  }
}
