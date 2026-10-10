import 'product.dart';

enum OfferType {
  export('عرض تصدير'),
  import('عرض استيراد');

  const OfferType(this.label);
  final String label;
}

/// A trade offer shown in the marketplace.
///
/// Besides the commercial data it carries the shipment details the exporter already knows
/// (packaging, departure, truck, cooling). The receiving party and the delivery city are left open:
/// an importer fills them in with an import request, which turns the offer into a [Shipment].
class TradingOffer {
  const TradingOffer({
    required this.id,
    required this.type,
    required this.product,
    required this.variety,
    required this.quantityTons,
    required this.pricePerTonJod,
    required this.origin,
    required this.allowedDestinations,
    required this.partner,
    required this.partnerContact,
    required this.description,
    required this.packaging,
    required this.departure,
    required this.truckType,
    required this.truckPlate,
    required this.driverName,
    required this.coolingSetpointC,
    this.smartCooling = true,
    this.imageAsset,
  });

  final String id;
  final OfferType type;
  final Product product;
  final String variety;
  final double quantityTons;
  final double pricePerTonJod;
  final String origin;

  /// Cities the exporter can deliver to; the importer picks one.
  final List<String> allowedDestinations;

  /// Supplying company (exporter for export offers, foreign supplier for import offers).
  final String partner;
  final String partnerContact;
  final String description;

  // Shipment template
  final String packaging;
  final DateTime departure;
  final String truckType;
  final String truckPlate;
  final String driverName;
  final double coolingSetpointC;
  final bool smartCooling;

  /// Product photo; null shows a coloured placeholder.
  final String? imageAsset;

  String get title => '${product.name} — $variety';
  String get destinationsLabel => allowedDestinations.join('، ');
}
