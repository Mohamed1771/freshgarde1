import 'package:flutter/material.dart';

import '../../../core/routing/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/trading_offer.dart';

Color offerTypeColor(OfferType t) => t == OfferType.export ? AppColors.primary : AppColors.secondary;

/// Offer card with the product photo and an export / import badge.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer});
  final TradingOffer offer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = offer;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, Routes.offerDetails, arguments: o.id),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(fit: StackFit.expand, children: [
              OfferImage(offer: o),
              PositionedDirectional(top: 10, start: 10, child: OfferTypeBadge(type: o.type)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.title, style: t.titleMedium),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.route_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(child: Text('${o.origin} ← ${o.destinationsLabel}', style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Text(Fmt.tons(o.quantityTons), style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(Fmt.money(o.pricePerTonJod), style: t.titleMedium?.copyWith(color: AppColors.primary)),
                Text(' / طن', style: t.bodySmall),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Product photo, or a coloured placeholder for products without one.
class OfferImage extends StatelessWidget {
  const OfferImage({super.key, required this.offer});
  final TradingOffer offer;

  @override
  Widget build(BuildContext context) {
    final asset = offer.imageAsset;
    if (asset != null) return Image.asset(asset, fit: BoxFit.cover);
    final c = offer.product.color;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [c.withValues(alpha: 0.25), c.withValues(alpha: 0.55)])),
      child: Center(
        child: Text(offer.product.name, style: const TextStyle(color: AppColors.white, fontSize: 30, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class OfferTypeBadge extends StatelessWidget {
  const OfferTypeBadge({super.key, required this.type});
  final OfferType type;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: offerTypeColor(type), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(type == OfferType.export ? Icons.north_east : Icons.south_west, size: 14, color: AppColors.white),
          const SizedBox(width: 4),
          Text(type.label, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ]),
      );
}

/// Offers in a responsive grid (1 column on phones, 2–3 on wider screens).
class OfferList extends StatelessWidget {
  const OfferList({super.key, required this.offers});
  final List<TradingOffer> offers;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 1000 ? 3 : (c.maxWidth >= 620 ? 2 : 1);
        final w = (c.maxWidth - 12 * (cols - 1)) / cols;
        return Wrap(spacing: 12, runSpacing: 12, children: [for (final o in offers) SizedBox(width: w, child: OfferCard(offer: o))]);
      });
}
