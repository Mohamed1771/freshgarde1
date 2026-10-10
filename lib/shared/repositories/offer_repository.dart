import 'package:flutter/foundation.dart';

import '../models/trading_offer.dart';
import 'mock_data.dart';

class OfferRepository extends ChangeNotifier {
  final List<TradingOffer> _offers = MockData.offers();

  List<TradingOffer> get all => List.unmodifiable(_offers);

  List<TradingOffer> byType(OfferType t) => _offers.where((o) => o.type == t).toList();

  TradingOffer? byId(String id) => _offers.where((o) => o.id == id).firstOrNull;
}
