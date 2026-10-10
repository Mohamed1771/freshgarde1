import 'product.dart';

enum OfferType {
  export('عرض تصدير'),
  import('عرض استيراد');

  const OfferType(this.label);
  final String label;
}

/// A trade offer shown in the marketplace (demo data).
class TradingOffer {
  const TradingOffer({
    required this.id,
    required this.type,
    required this.product,
    required this.variety,
    required this.imageAsset,
    required this.quantityTons,
    required this.pricePerTonJod,
    required this.origin,
    required this.destination,
    required this.partner,
    required this.description,
  });

  final String id;
  final OfferType type;
  final Product product;
  final String variety;
  final String imageAsset;
  final double quantityTons;
  final double pricePerTonJod;
  final String origin;
  final String destination;

  /// Seller for export offers, buyer for import offers.
  final String partner;
  final String description;

  String get title => '${product.name} — $variety';
}
