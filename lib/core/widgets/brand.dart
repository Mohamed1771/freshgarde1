import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The FreshGarde logo (transparent PNG).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 72});
  final double size;

  static const asset = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) =>
      Image.asset(asset, width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.medium);
}

class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.light = false});
  final bool light;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = light ? AppColors.white : AppColors.navy;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('FreshGarde', style: t.headlineMedium?.copyWith(color: c), textDirection: TextDirection.ltr),
      Text('منصة التجارة الزراعية والنقل المبرّد الذكي', style: t.bodyMedium?.copyWith(color: c.withValues(alpha: 0.75))),
    ]);
  }
}
