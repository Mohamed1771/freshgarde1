import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/trading_offer.dart';
import 'mock_data.dart';
import 'notification_repository.dart';

class DealRepository extends ChangeNotifier {
  DealRepository(this._notifications) {
    final offers = MockData.offers();
    final now = DateTime.now();
    _items.addAll([
      DealRequest(
        id: 'DL-501', offer: offers[0], quantityTons: 6, deliveryDate: now.add(const Duration(days: 5)),
        deliveryCity: 'دبي', paymentTerms: MockData.paymentTerms[1], needsRefrigeratedTransport: true,
        notes: 'نرغب بالتسليم صباحًا في سوق العوير.', counterparty: 'مؤسسة الإمارات للأغذية الطازجة', incoming: true,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      DealRequest(
        id: 'DL-498', offer: offers[3], quantityTons: 15, deliveryDate: now.add(const Duration(days: 9)),
        deliveryCity: 'عمّان', paymentTerms: MockData.paymentTerms[2], needsRefrigeratedTransport: false,
        notes: '', counterparty: offers[3].sellerName, incoming: false, status: DealStatus.accepted,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ]);
  }

  final NotificationRepository _notifications;
  final List<DealRequest> _items = [];
  int _seq = 510;

  List<DealRequest> get outgoing => _items.where((d) => !d.incoming).toList();
  List<DealRequest> get incoming => _items.where((d) => d.incoming).toList();
  int get pendingIncoming => incoming.where((d) => d.status == DealStatus.pending).length;

  String nextId() => 'DL-${_seq++}';

  Future<void> submit(DealRequest d) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _items.insert(0, d);
    _notifications.add(NotificationType.deal, 'تم إرسال طلب الصفقة ${d.id}',
        'طلبك لشراء ${d.quantityTons} طن من ${d.offer.title} أُرسل إلى ${d.counterparty}.');
    notifyListeners();
  }

  void respond(DealRequest d, DealStatus status) {
    d.status = status;
    _notifications.add(NotificationType.deal, 'تم تحديث الصفقة ${d.id}', 'الحالة الجديدة: ${status.label}.');
    notifyListeners();
  }
}
