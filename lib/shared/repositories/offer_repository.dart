import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../models/trading_offer.dart';
import 'mock_data.dart';

enum OfferSort {
  newest('الأحدث'),
  priceLow('السعر: من الأقل'),
  priceHigh('السعر: من الأعلى'),
  quantity('الكمية الأكبر');

  const OfferSort(this.label);
  final String label;
}

/// Immutable filter set for the marketplace.
class OfferFilter {
  const OfferFilter({
    this.query = '',
    this.category,
    this.origin,
    this.destination,
    this.availableNowOnly = false,
    this.verifiedOnly = false,
    this.sort = OfferSort.newest,
  });

  final String query;
  final ProductCategory? category;
  final String? origin;
  final String? destination;
  final bool availableNowOnly;
  final bool verifiedOnly;
  final OfferSort sort;

  int get activeCount =>
      [category, origin, destination].where((e) => e != null).length + (availableNowOnly ? 1 : 0) + (verifiedOnly ? 1 : 0);

  OfferFilter copyWith({
    String? query,
    ProductCategory? Function()? category,
    String? Function()? origin,
    String? Function()? destination,
    bool? availableNowOnly,
    bool? verifiedOnly,
    OfferSort? sort,
  }) =>
      OfferFilter(
        query: query ?? this.query,
        category: category != null ? category() : this.category,
        origin: origin != null ? origin() : this.origin,
        destination: destination != null ? destination() : this.destination,
        availableNowOnly: availableNowOnly ?? this.availableNowOnly,
        verifiedOnly: verifiedOnly ?? this.verifiedOnly,
        sort: sort ?? this.sort,
      );
}

class OfferRepository extends ChangeNotifier {
  final List<TradingOffer> _offers = MockData.offers();

  List<TradingOffer> get all => List.unmodifiable(_offers);

  TradingOffer? byId(String id) => _offers.where((o) => o.id == id).firstOrNull;

  List<TradingOffer> search(OfferFilter f) {
    final q = f.query.trim();
    final res = _offers.where((o) {
      if (q.isNotEmpty &&
          !('${o.product.name} ${o.variety} ${o.sellerName} ${o.origin} ${o.destination}').contains(q)) {
        return false;
      }
      if (f.category != null && o.product.category != f.category) return false;
      if (f.origin != null && o.origin != f.origin) return false;
      if (f.destination != null && o.destination != f.destination) return false;
      if (f.availableNowOnly && o.availability == Availability.preOrder) return false;
      if (f.verifiedOnly && !o.sellerVerified) return false;
      return true;
    }).toList();

    switch (f.sort) {
      case OfferSort.newest:
        res.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      case OfferSort.priceLow:
        res.sort((a, b) => a.pricePerTonJod.compareTo(b.pricePerTonJod));
      case OfferSort.priceHigh:
        res.sort((a, b) => b.pricePerTonJod.compareTo(a.pricePerTonJod));
      case OfferSort.quantity:
        res.sort((a, b) => b.quantityTons.compareTo(a.quantityTons));
    }
    return res;
  }
}
