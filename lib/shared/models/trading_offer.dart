import 'product.dart';

enum Availability {
  available('متوفر'),
  limited('كمية محدودة'),
  preOrder('حجز مسبق');

  const Availability(this.label);
  final String label;
}

/// An export offer published by a seller and browsable by importers.
class TradingOffer {
  const TradingOffer({
    required this.id,
    required this.product,
    required this.variety,
    required this.quantityTons,
    required this.minOrderTons,
    required this.pricePerTonJod,
    required this.origin,
    required this.destination,
    required this.sellerName,
    required this.sellerVerified,
    required this.sellerRating,
    required this.availability,
    required this.availableFrom,
    required this.grade,
    required this.description,
    required this.publishedAt,
  });

  final String id;
  final Product product;
  final String variety;
  final double quantityTons;
  final double minOrderTons;
  final double pricePerTonJod;
  final String origin;
  final String destination;
  final String sellerName;
  final bool sellerVerified;
  final double sellerRating;
  final Availability availability;
  final DateTime availableFrom;
  final String grade;
  final String description;
  final DateTime publishedAt;

  String get title => '${product.name} — $variety';
}

enum DealStatus {
  pending('بانتظار الرد'),
  accepted('مقبول'),
  rejected('مرفوض'),
  cancelled('ملغى');

  const DealStatus(this.label);
  final String label;
}

/// A purchase request sent by an importer for a [TradingOffer].
class DealRequest {
  DealRequest({
    required this.id,
    required this.offer,
    required this.quantityTons,
    required this.deliveryDate,
    required this.deliveryCity,
    required this.paymentTerms,
    required this.needsRefrigeratedTransport,
    required this.notes,
    required this.counterparty,
    required this.incoming,
    this.status = DealStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final TradingOffer offer;
  final double quantityTons;
  final DateTime deliveryDate;
  final String deliveryCity;
  final String paymentTerms;
  final bool needsRefrigeratedTransport;
  final String notes;

  /// The other party: the seller for outgoing requests, the buyer for incoming ones.
  final String counterparty;

  /// True when another trader sent this request to the current user.
  final bool incoming;
  DealStatus status;
  final DateTime createdAt;

  double get totalJod => quantityTons * offer.pricePerTonJod;
}
