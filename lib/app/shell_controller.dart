import 'package:flutter/foundation.dart';

import '../shared/models/shipment.dart';

/// Main tabs of the bottom navigation.
enum MainTab { home, marketplace, shipments, profile }

/// Lets any screen switch the bottom-navigation tab (e.g. "view in My Shipments" after creating one).
class ShellController extends ChangeNotifier {
  MainTab tab = MainTab.home;
  ShipmentStatus shipmentsTab = ShipmentStatus.active;

  void go(MainTab t) {
    tab = t;
    notifyListeners();
  }

  void openShipments(ShipmentStatus status) {
    shipmentsTab = status;
    tab = MainTab.shipments;
    notifyListeners();
  }

  void openMarketplace() => go(MainTab.marketplace);

  void reset() {
    tab = MainTab.home;
    shipmentsTab = ShipmentStatus.active;
  }
}
