import 'package:flutter/material.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_visual.dart';
import '../../../shared/models/shipment.dart';

Color shipmentStatusColor(ShipmentStatus s) => switch (s) {
      ShipmentStatus.active => AppColors.primary,
      ShipmentStatus.pending => AppColors.warning,
      ShipmentStatus.delivered => AppColors.success,
      ShipmentStatus.archived => AppColors.textSecondary,
    };

class ShipmentCard extends StatelessWidget {
  const ShipmentCard({super.key, required this.shipment});
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final s = shipment;
    final t = Theme.of(context).textTheme;
    final critical = s.hasUnresolvedCritical && s.status == ShipmentStatus.active;
    return AppCard(
      onTap: () => Navigator.pushNamed(context, Routes.shipmentDetails, arguments: s.id),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ProductThumb(product: s.product, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(s.id, style: t.titleSmall, textDirection: TextDirection.ltr),
                if (critical) ...[const SizedBox(width: 6), const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.danger)],
              ]),
              Text('${s.product.name} • ${Fmt.tons(s.quantityTons)}', style: t.bodySmall),
            ]),
          ),
          StatusChip(label: s.status.label, color: shipmentStatusColor(s.status), icon: s.status.icon, dense: true),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.route_outlined, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: Text(s.route, style: t.bodyMedium)),
          Text('الوصول ${Fmt.date(s.eta)}', style: t.bodySmall),
        ]),
        if (s.status == ShipmentStatus.active) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: s.progress, minHeight: 6, backgroundColor: AppColors.ice),
          ),
        ],
        const SizedBox(height: 10),
        Row(children: [
          _mini(context, Icons.thermostat, Fmt.temp(s.reading.temperatureC),
              (s.reading.temperatureC - s.coolingSetpointC).abs() > 3 ? AppColors.danger : AppColors.primary),
          const SizedBox(width: 14),
          _mini(context, Icons.water_drop_outlined, Fmt.pct(s.reading.humidityPct), AppColors.sky),
          const Spacer(),
          StatusChip(label: 'الحالة: ${s.condition.label}', color: s.condition.color, dense: true),
        ]),
      ]),
    );
  }

  Widget _mini(BuildContext context, IconData i, String v, Color c) => Row(children: [
        Icon(i, size: 18, color: c),
        const SizedBox(width: 2),
        Text(v, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c, fontWeight: FontWeight.w600)),
      ]);
}
