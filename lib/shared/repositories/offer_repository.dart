import 'package:flutter/foundation.dart';

import '../models/trading_offer.dart';
import 'mock_data.dart';

/// In-memory marketplace. Offers are added by exporters who list a shipment without a known
/// receiver, and removed once an importer requests them.
class OfferRepository extends ChangeNotifier {
  final List<TradingOffer> _offers = MockData.offers();
  int _seq = 300;

  List<TradingOffer> get all => List.unmodifiable(_offers);

  List<TradingOffer> byType(OfferType t) => _offers.where((o) => o.type == t).toList();

  TradingOffer? byId(String id) => _offers.where((o) => o.id == id).firstOrNull;

  String nextId() => 'OF-${_seq++}';

  Future<void> add(TradingOffer offer) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _offers.insert(0, offer);
    notifyListeners();
  }

  void remove(String id) {
    _offers.removeWhere((o) => o.id == id);
    notifyListeners();
  }
}
