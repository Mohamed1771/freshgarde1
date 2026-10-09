import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../shared/models/product.dart';
import '../../shared/models/shipment.dart';
import '../../shared/models/trading_offer.dart';
import '../../shared/repositories/deal_repository.dart';
import '../../shared/repositories/shipment_repository.dart';
import '../shipments/widgets/shipment_card.dart';

/// Reports computed live from the in-memory repositories.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final shipments = context.watch<ShipmentRepository>().all;
    final deals = context.watch<DealRepository>();
    final volume = shipments.fold<double>(0, (s, e) => s + e.quantityTons);
    final avgQuality = shipments.isEmpty ? 0.0 : shipments.fold<double>(0, (s, e) => s + e.qualityPct) / shipments.length;
    final alerts = shipments.fold<int>(0, (s, e) => s + e.alerts.length);
    final inspected = shipments.where((s) => s.inspection != null).length;

    final byProduct = <Product, double>{};
    for (final s in shipments) {
      byProduct[s.product] = (byProduct[s.product] ?? 0) + s.quantityTons;
    }
    final productRows = byProduct.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxVol = productRows.isEmpty ? 1.0 : productRows.first.value;

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ResponsiveBody(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Align(alignment: AlignmentDirectional.centerStart, child: MockBadge(label: 'مبنية على بيانات تجريبية')),
            const SizedBox(height: 12),
            TileGrid(children: [
              MetricTile(icon: Icons.local_shipping_outlined, label: 'إجمالي الشحنات', value: '${shipments.length}'),
              MetricTile(icon: Icons.scale_outlined, label: 'الحجم الكلي', value: Fmt.tons(volume)),
              MetricTile(icon: Icons.star_outline, label: 'متوسط الجودة', value: Fmt.pct(avgQuality), color: CargoCondition.fromQuality(avgQuality).color),
              MetricTile(icon: Icons.warning_amber_rounded, label: 'التنبيهات', value: '$alerts', color: alerts > 0 ? AppColors.warning : AppColors.success),
              MetricTile(icon: Icons.document_scanner_outlined, label: 'شحنات مفحوصة', value: '$inspected/${shipments.length}', color: AppColors.sky),
              MetricTile(icon: Icons.handshake_outlined, label: 'صفقات مقبولة', value: '${[...deals.outgoing, ...deals.incoming].where((d) => d.status == DealStatus.accepted).length}', color: AppColors.success),
            ]),
            const SizedBox(height: 16),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الشحنات حسب الحالة', style: t.titleSmall),
                const SizedBox(height: 10),
                for (final st in ShipmentStatus.values)
                  _bar(context, st.label, shipments.where((s) => s.status == st).length.toDouble(), shipments.length.toDouble(),
                      shipmentStatusColor(st), '${shipments.where((s) => s.status == st).length}'),
              ]),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الحجم حسب المنتج', style: t.titleSmall),
                const SizedBox(height: 10),
                if (productRows.isEmpty) Text('لا توجد بيانات', style: t.bodyMedium),
                for (final e in productRows) _bar(context, '${e.key.emoji} ${e.key.name}', e.value, maxVol, e.key.color, Fmt.tons(e.value)),
              ]),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('جودة الشحنات', style: t.titleSmall),
                const SizedBox(height: 10),
                for (final s in shipments) _bar(context, s.id, s.qualityPct, 100, s.condition.color, Fmt.pct(s.qualityPct)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _bar(BuildContext context, String label, double v, double max, Color c, String trailing) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          SizedBox(width: 110, child: Text(label, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: max == 0 ? 0 : (v / max).clamp(0, 1), minHeight: 12, color: c, backgroundColor: AppColors.ice),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 56, child: Text(trailing, style: Theme.of(context).textTheme.bodySmall)),
        ]),
      );
}
