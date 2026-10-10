import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common.dart';
import '../../shared/models/trading_offer.dart';
import '../../shared/repositories/offer_repository.dart';
import 'widgets/offer_card.dart';

/// Marketplace: export and import offers.
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<OfferRepository>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        ResponsiveBody(
          maxWidth: 1100,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final type in OfferType.values) ...[
              SectionHeader(type == OfferType.export ? 'عروض التصدير' : 'عروض الاستيراد'),
              OfferList(offers: repo.byType(type)),
              const SizedBox(height: 8),
            ],
          ]),
        ),
      ],
    );
  }
}
