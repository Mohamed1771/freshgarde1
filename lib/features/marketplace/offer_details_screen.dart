import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../shared/repositories/offer_repository.dart';
import 'widgets/offer_card.dart';

class OfferDetailsScreen extends StatelessWidget {
  const OfferDetailsScreen({super.key, required this.offerId});
  final String offerId;

  @override
  Widget build(BuildContext context) {
    final o = context.watch<OfferRepository>().byId(offerId);
    if (o == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.inventory_2_outlined, title: 'هذا العرض لم يعد متاحًا', message: 'ربما تم طلبه من مستورد آخر.'),
      );
    }
    final t = Theme.of(context).textTheme;
    final p = o.product;

    return Scaffold(
      appBar: AppBar(title: Text(o.title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, Routes.importRequest, arguments: o.id),
            icon: const Icon(Icons.download_rounded),
            label: const Text('طلب استيراد'),
          ),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ResponsiveBody(
          maxWidth: 760,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(fit: StackFit.expand, children: [
                  OfferImage(offer: o),
                  PositionedDirectional(top: 12, start: 12, child: OfferTypeBadge(type: o.type)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Text(o.title, style: t.headlineSmall),
            Row(children: [
              Text(Fmt.money(o.pricePerTonJod), style: t.headlineMedium?.copyWith(color: AppColors.primary)),
              Text(' / طن', style: t.bodyMedium),
            ]),
            const SizedBox(height: 12),
            Text(o.description, style: t.bodyMedium),
            const SizedBox(height: 16),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                InfoRow(icon: Icons.swap_horiz, label: 'نوع العرض', value: o.type.label, valueColor: offerTypeColor(o.type)),
                InfoRow(icon: Icons.scale_outlined, label: 'الكمية', value: Fmt.tons(o.quantityTons)),
                InfoRow(icon: Icons.inventory_2_outlined, label: 'التعبئة', value: o.packaging),
                InfoRow(icon: Icons.place_outlined, label: 'المنشأ', value: o.origin),
                InfoRow(icon: Icons.flag_outlined, label: 'مدن التسليم المتاحة', value: o.destinationsLabel),
                InfoRow(icon: Icons.event_outlined, label: 'تاريخ الانطلاق', value: Fmt.date(o.departure)),
                InfoRow(icon: Icons.storefront_outlined, label: 'المورّد', value: o.partner),
                InfoRow(icon: Icons.thermostat, label: 'حرارة النقل', value: Fmt.temp(o.coolingSetpointC)),
                InfoRow(icon: Icons.water_drop_outlined, label: 'الرطوبة', value: Fmt.pct(p.optimalHumidity)),
              ]),
            ),
            const SizedBox(height: 12),
            const InlineMessage(text: 'اطلب هذا العرض لتحديد مدينة التسليم وبيانات الجهة المستلمة، وتُنشأ الشحنة مباشرة.'),
          ]),
        ),
      ]),
    );
  }
}
