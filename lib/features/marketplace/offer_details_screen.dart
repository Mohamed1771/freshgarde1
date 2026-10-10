import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../shared/models/trading_offer.dart';
import '../../shared/repositories/offer_repository.dart';
import 'widgets/offer_card.dart';

class OfferDetailsScreen extends StatelessWidget {
  const OfferDetailsScreen({super.key, required this.offerId});
  final String offerId;

  @override
  Widget build(BuildContext context) {
    final o = context.watch<OfferRepository>().byId(offerId);
    if (o == null) {
      return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.search_off, title: 'العرض غير موجود'));
    }
    final t = Theme.of(context).textTheme;
    final p = o.product;

    return Scaffold(
      appBar: AppBar(title: Text(o.title)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ResponsiveBody(
          maxWidth: 760,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(o.imageAsset, fit: BoxFit.cover),
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
                InfoRow(icon: Icons.place_outlined, label: 'المنشأ', value: o.origin),
                InfoRow(icon: Icons.flag_outlined, label: 'الوجهة', value: o.destination),
                InfoRow(
                  icon: Icons.storefront_outlined,
                  label: o.type == OfferType.export ? 'المصدّر' : 'المورّد',
                  value: o.partner,
                ),
                InfoRow(icon: Icons.thermostat, label: 'حرارة النقل', value: Fmt.temp(p.optimalTempC)),
                InfoRow(icon: Icons.water_drop_outlined, label: 'الرطوبة', value: Fmt.pct(p.optimalHumidity)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
