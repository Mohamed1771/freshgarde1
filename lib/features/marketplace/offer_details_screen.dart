import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/product_visual.dart';
import '../../shared/repositories/offer_repository.dart';
import 'widgets/offer_card.dart';

class OfferDetailsScreen extends StatelessWidget {
  const OfferDetailsScreen({super.key, required this.offerId});
  final String offerId;

  @override
  Widget build(BuildContext context) {
    final offer = context.watch<OfferRepository>().byId(offerId);
    if (offer == null) {
      return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.search_off, title: 'العرض غير موجود'));
    }
    final t = Theme.of(context).textTheme;
    final p = offer.product;

    return Scaffold(
      appBar: AppBar(title: Text(offer.title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, Routes.dealRequest, arguments: offer.id),
            icon: const Icon(Icons.handshake_outlined),
            label: const Text('طلب صفقة'),
          ),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ResponsiveBody(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ProductBanner(product: p),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text(offer.title, style: t.headlineSmall)),
              StatusChip(label: offer.availability.label, color: availabilityColor(offer.availability)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Text(Fmt.money(offer.pricePerTonJod), style: t.headlineMedium?.copyWith(color: AppColors.primary)),
              Text(' / طن', style: t.bodyMedium),
            ]),
            const SizedBox(height: 16),
            TileGrid(children: [
              MetricTile(icon: Icons.scale_outlined, label: 'الكمية المتاحة', value: Fmt.tons(offer.quantityTons)),
              MetricTile(icon: Icons.low_priority, label: 'الحد الأدنى للطلب', value: Fmt.tons(offer.minOrderTons)),
              MetricTile(icon: Icons.thermostat, label: 'حرارة النقل الموصى بها', value: Fmt.temp(p.optimalTempC), color: AppColors.sky),
              MetricTile(icon: Icons.water_drop_outlined, label: 'الرطوبة الموصى بها', value: Fmt.pct(p.optimalHumidity), color: AppColors.sky),
            ]),
            const SizedBox(height: 16),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('تفاصيل العرض', style: t.titleMedium),
                const SizedBox(height: 8),
                InfoRow(icon: Icons.category_outlined, label: 'التصنيف', value: p.category.label),
                InfoRow(icon: Icons.grade_outlined, label: 'الدرجة', value: offer.grade),
                InfoRow(icon: Icons.agriculture_outlined, label: 'المنشأ', value: offer.origin),
                InfoRow(icon: Icons.flag_outlined, label: 'الوجهة المقترحة', value: offer.destination),
                InfoRow(icon: Icons.event_available_outlined, label: 'متاح من', value: Fmt.date(offer.availableFrom)),
                InfoRow(icon: Icons.schedule, label: 'تاريخ النشر', value: Fmt.ago(offer.publishedAt)),
                const SizedBox(height: 8),
                Text(offer.description, style: t.bodyMedium),
              ]),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Row(children: [
                CircleAvatar(radius: 24, backgroundColor: AppColors.ice, child: Text(offer.sellerName.substring(0, 1), style: t.titleMedium)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text(offer.sellerName, style: t.titleSmall)),
                      if (offer.sellerVerified) ...[const SizedBox(width: 4), const Icon(Icons.verified, size: 18, color: AppColors.primary)],
                    ]),
                    Text(offer.sellerVerified ? 'بائع موثّق' : 'بائع غير موثّق بعد', style: t.bodySmall),
                  ]),
                ),
                const Icon(Icons.star_rounded, color: AppColors.warning),
                Text(offer.sellerRating.toStringAsFixed(1), style: t.titleSmall),
              ]),
            ),
            const SizedBox(height: 12),
            const InlineMessage(text: 'العروض والأسعار المعروضة بيانات تجريبية لأغراض العرض فقط.', color: AppColors.warning, icon: Icons.science_outlined),
          ]),
        ),
      ]),
    );
  }
}
