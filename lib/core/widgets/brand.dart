import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The FreshRoute logo (`assets/images/logo.webp`, white background).
/// [light] puts it on a white rounded tile for use over coloured surfaces.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 72, this.light = false});
  final double size;
  final bool light;

  static const asset = 'assets/images/logo.webp';

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(asset, width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.medium);
    if (!light) return image;
    return Container(
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [BoxShadow(color: AppColors.navy.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: image,
    );
  }
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
