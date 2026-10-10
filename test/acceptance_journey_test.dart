import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshroute_platform/shared/models/shipment.dart';
import 'package:freshroute_platform/shared/repositories/shipment_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'helpers.dart';

/// Main journey through the real UI: login → home → marketplace → export shipment with a known
/// receiver → My Shipments → live simulation (departure, time passing, scenario alerts).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('full demo journey', (t) async {
    await launchAndLogin(t);
    expect(find.text('العروض المتاحة'), findsOneWidget);

    // Marketplace: three photo offers, two export and one import.
    await tapText(t, 'استيراد');
    expect(find.text('عروض التصدير'), findsOneWidget);
    expect(find.text('عروض الاستيراد'), findsOneWidget);
    expect(find.text('عرض تصدير'), findsNWidgets(2));
    expect(find.text('عرض استيراد'), findsOneWidget);

    // Create export shipment (5 steps).
    await tapText(t, 'الرئيسية', last: true);
    await tapText(t, 'تصدير');
    expect(find.text('إنشاء شحنة تصدير'), findsOneWidget);
    await tapText(t, 'التالي'); // Step 1 is prefilled from the profile.

    // Receiver known: importer details, arrival city and date.
    await tapText(t, 'نعم، المستقبِل معلوم');
    await enter(t, 'اسم الشركة المستوردة', 'الدوحة للخضار');
    await enter(t, 'اسم المسؤول لدى المستورد', 'ناصر');
    await pick(t, 'دولة المستورد', 'قطر');
    await enter(t, 'هاتف المستورد (دولي)', '+97455512345');
    await pick(t, 'مدينة الوصول', 'الدوحة');
    await enter(t, 'عنوان التسليم', 'السوق المركزي');
    await pickDate(t, 'تاريخ الوصول المتوقع');
    await tapText(t, 'التالي');

    await fillProductAndTransport(t);

    expect(find.text('المراجعة'), findsWidgets);
    await tapText(t, 'أؤكد صحة بيانات الشحنة ومطابقتها للمستندات المرفقة.');
    await tapText(t, 'تأكيد وإنشاء الشحنة');
    await settle(t);

    // Success → view in My Shipments (pending tab).
    await tapText(t, 'عرض في شحناتي');
    await settle(t, 500);
    final repo = Provider.of<ShipmentRepository>(t.element(find.byType(Scaffold).first), listen: false);
    final created = repo.byStatus(ShipmentStatus.pending).first;
    expect(created.variety, 'بندورة شيري');
    expect(find.text(created.id), findsOneWidget);

    // Shipment details (live simulation view, pending).
    await tapText(t, created.id);
    expect(find.text('الشحنة ${created.id}'), findsOneWidget);
    expect(find.text('الشحنة بانتظار الانطلاق'), findsOneWidget);
    final tempBefore = created.reading.temperatureC;

    // No simulation controls: the trip runs on its own once the truck departs.
    expect(find.text('تشغيل'), findsNothing);
    expect(find.text('عطل التبريد'), findsNothing);
    // pumpAndSettle would fast-forward the running trip, so only pump single frames from here on.
    await t.tap(find.text('انطلاق الشاحنة'));
    await t.pump();
    expect(created.status, ShipmentStatus.active);

    // Let ~20 simulated hours pass (0.5 h per second).
    for (var i = 0; i < 200; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(find.textContaining('الساعة 2'), findsWidgets);
    expect(created.progress, greaterThan(0.2)); // written back every ~2 s of real time
    expect(created.reading.temperatureC, isNot(tempBefore));
    // The scenario's scripted events raised alerts on the shipment.
    expect(created.alerts.any((a) => a.source == 'simulation'), isTrue);
  });
}
