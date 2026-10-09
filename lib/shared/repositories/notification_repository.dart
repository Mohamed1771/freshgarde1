import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import 'mock_data.dart';

class NotificationRepository extends ChangeNotifier {
  final List<AppNotification> _items = MockData.notifications();
  int _seq = 100;

  /// When false (Settings), new notifications are still stored but not counted as unread.
  bool enabled = true;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.read).length;

  void add(NotificationType type, String title, String body, {String? shipmentId}) {
    _items.insert(0, AppNotification(id: 'N-${_seq++}', type: type, title: title, body: body, shipmentId: shipmentId, read: !enabled));
    notifyListeners();
  }

  void markRead(AppNotification n) {
    if (n.read) return;
    n.read = true;
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _items) {
      n.read = true;
    }
    notifyListeners();
  }

  void remove(AppNotification n) {
    _items.remove(n);
    notifyListeners();
  }
}
