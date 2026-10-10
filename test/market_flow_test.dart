import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshroute_platform/shared/models/shipment.dart';
import 'package:freshroute_platform/shared/models/trading_offer.dart';
import 'package:freshroute_platform/shared/repositories/offer_repository.dart';
import 'package:freshroute_platform/shared/repositories/shipment_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'helpers.dart';

/// Export without a known receiver → listed in the market → an importer requests it,
/// fills the delivery city and receiving party → a pending shipment is created.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('list a shipment in the market, then import it', (t) async {
    await launchAndLogin(t);
    final ctx = t.element(find.byType(Scaffold).first);
    final offers = Provider.of<OfferRepository>(ctx, listen: false);
    final shipments = Provider.of<ShipmentRepository>(ctx, listen: false);
    final offersBefore = offers.all.length;
    final shipmentsBefore = shipments.all.length;

    // Export wizard, receiver unknown → choose cities and price.
    await tapText(t, 'تصدير');
    await tapText(t, 'التالي');
    await tapText(t, 'التالي'); // no choice yet → validation
    expect(find.text('اختر أحد الخيارين'), findsOneWidget);
    await tapText(t, 'لا، اعرضها في السوق');
    await tapText(t, 'التالي'); // no city yet → validation
    expect(find.text('اختر مدينة واحدة على الأقل'), findsOneWidget);
    await tapText(t, 'دبي');
    await tapText(t, 'الدوحة');
    await enter(t, 'السعر المطلوب (دينار للطن)', '500');
    await tapText(t, 'التالي');

    await fillProductAndTransport(t);
    expect(find.text('العرض في السوق'), findsOneWidget);
    await tapText(t, 'أؤكد صحة بيانات الشحنة ومطابقتها للمستندات المرفقة.');
    await tapText(t, 'عرض الشحنة في السوق');
    await settle(t);

    // Listed as an export offer; no shipment yet.
    expect(offers.all.length, offersBefore + 1);
    expect(shipments.all.length, shipmentsBefore);
    final listed = offers.all.first;
    expect(listed.type, OfferType.export);
    expect(listed.allowedDestinations, ['دبي', 'الدوحة']);
    await tapText(t, 'عرض في السوق');
    expect(find.text('عرض تصدير'), findsNWidgets(3));

    // Importer: open the offer → import request → fill the missing details.
    await tapText(t, 'بندورة — بندورة شيري');
    await tapText(t, 'طلب استيراد');
    await pick(t, 'مدينة التسليم', 'الدوحة');
    await enter(t, 'عنوان التسليم', 'سوق الخضار المركزي');
    await pickDate(t, 'تاريخ الوصول المطلوب');
    await pick(t, 'دولة الجهة المستلمة', 'قطر');
    await tapText(t, 'أؤكد طلب هذه الشحنة وصحة بيانات التسليم.');
    await tapText(t, 'إرسال الطلب وإنشاء الشحنة');
    await settle(t);

    // Offer turned into a pending shipment to the chosen city and left the market.
    expect(offers.byId(listed.id), isNull);
    expect(shipments.all.length, shipmentsBefore + 1);
    final created = shipments.byStatus(ShipmentStatus.pending).first;
    expect(created.destination, 'الدوحة');
    expect(created.importerCountry, 'قطر');
    expect(created.variety, 'بندورة شيري');
    await tapText(t, 'عرض في شحناتي');
    expect(find.text(created.id), findsOneWidget);
  });
}
