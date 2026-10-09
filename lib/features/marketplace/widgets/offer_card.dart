import 'package:flutter/material.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_visual.dart';
import '../../../shared/models/trading_offer.dart';

Color availabilityColor(Availability a) => switch (a) {
      Availability.available => AppColors.success,
      Availability.limited => AppColors.warning,
      Availability.preOrder => AppColors.sky,
    };

/// Trading offer summary card: image, quantity, origin, destination, seller, price, availability.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer});
  final TradingOffer offer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      onTap: () => Navigator.pushNamed(context, Routes.offerDetails, arguments: offer.id),
      padding: const EdgeInsets.all(12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ProductThumb(product: offer.product, size: 84),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(offer.title, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
              StatusChip(label: offer.availability.label, color: availabilityColor(offer.availability), dense: true),
            ]),
            const SizedBox(height: 4),
            _line(context, Icons.route_outlined, '${offer.origin} ← ${offer.destination}'),
            _line(context, Icons.scale_outlined, '${Fmt.tons(offer.quantityTons)} • حد أدنى ${Fmt.tons(offer.minOrderTons)}'),
            Row(children: [
              Expanded(child: _line(context, Icons.storefront_outlined, offer.sellerName)),
              if (offer.sellerVerified) const Icon(Icons.verified, size: 16, color: AppColors.primary),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: Fmt.money(offer.pricePerTonJod), style: t.titleMedium?.copyWith(color: AppColors.primary)),
                    TextSpan(text: ' / طن', style: t.bodySmall),
                  ])),
                ),
              ),
              const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
              Text(offer.sellerRating.toStringAsFixed(1), style: t.bodySmall),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _line(BuildContext context, IconData i, String s) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(children: [
          Icon(i, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: Text(s, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      );
}

/// Responsive list → grid of offers.
class OfferList extends StatelessWidget {
  const OfferList({super.key, required this.offers});
  final List<TradingOffer> offers;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 1100 ? 3 : (c.maxWidth >= 700 ? 2 : 1);
        final w = (c.maxWidth - 12 * (cols - 1)) / cols;
        return Wrap(spacing: 12, runSpacing: 12, children: [for (final o in offers) SizedBox(width: w, child: OfferCard(offer: o))]);
      });
}
