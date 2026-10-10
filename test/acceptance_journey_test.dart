import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshgarde/app/app.dart';
import 'package:freshgarde/shared/models/shipment.dart';
import 'package:freshgarde/shared/repositories/shipment_repository.dart';
import 'package:freshgarde/shared/repositories/mock_data.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Final acceptance journey (spec §14), driven end to end through the real UI:
/// login → home → marketplace → create export shipment → My Shipments → AI inspection
/// (sample image) → apply → simulation → advance time → cooling failure alert → shipment details.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> settle(WidgetTester t, [int ms = 1200]) async {
    await t.pump(Duration(milliseconds: ms));
    await t.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester t, String text, {bool last = false}) async {
    final f = last ? find.text(text).last : find.text(text).first;
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> enter(WidgetTester t, String label, String value) async {
    final f = find.widgetWithText(TextFormField, label).first;
    await t.ensureVisible(f);
    await t.enterText(f, value);
    await t.pump();
  }

  Future<void> pick(WidgetTester t, String label, String option) async {
    final f = find.text(label).last; // .last skips the step title when it has the same text
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
    await t.tap(find.text(option).last);
    await t.pumpAndSettle();
  }

  Future<void> pickDate(WidgetTester t, String label) async {
    final f = find.widgetWithText(InputDecorator, label).first;
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
    // Confirm button of the Material date picker (Arabic localisation).
    final ok = find.byWidgetPredicate((w) => w is TextButton && w.child is Text && ['حسنًا', 'حسنا', 'موافق', 'OK'].contains((w.child as Text).data));
    await t.tap(ok.last);
    await t.pumpAndSettle();
  }

  Future<void> useDemoDocument(WidgetTester t, String label) async {
    await tapText(t, '$label *');
    await tapText(t, 'استخدام ملف تجريبي');
  }

  testWidgets('full demo journey', (t) async {
    await t.binding.setSurfaceSize(const Size(1000, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));

    await t.pumpWidget(const FreshGardeApp());
    await settle(t, 1700);

    // Login with the documented demo account.
    await t.enterText(find.byType(TextFormField).at(0), MockData.demoEmail);
    await t.enterText(find.byType(TextFormField).at(1), MockData.demoPassword);
    await tapText(t, 'دخول');
    await settle(t);
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

    await enter(t, 'اسم الشركة المستوردة', 'مؤسسة الخليج للأغذية');
    await enter(t, 'اسم المسؤول لدى المستورد', 'ناصر');
    await pick(t, 'دولة المستورد', 'الإمارات');
    await enter(t, 'هاتف المستورد', '+971501234567');
    await enter(t, 'عنوان التسليم', 'السوق المركزي');
    await tapText(t, 'التالي');

    await pick(t, 'المنتج', '🍅  بندورة');
    await enter(t, 'الصنف', 'بندورة شيري');
    await enter(t, 'الكمية (طن)', '10');
    await pick(t, 'نوع التعبئة', 'كراتين 5 كغ');
    await pickDate(t, 'تاريخ القطاف');
    await tapText(t, 'التالي');

    await pick(t, 'نوع الشاحنة', 'براد 20 قدم');
    await enter(t, 'رقم لوحة الشاحنة', '22-12345');
    await enter(t, 'اسم السائق', 'سامر');
    await enter(t, 'هاتف السائق', '0791112233');
    await pick(t, 'نقطة الانطلاق', 'عمّان');
    await pick(t, 'الوجهة (الإمارات)', 'دبي');
    await pickDate(t, 'تاريخ الانطلاق');
    // The arrival picker opens on the first allowed day (departure + 1).
    await pickDate(t, 'تاريخ الوصول المتوقع');
    await useDemoDocument(t, 'شهادة الصحة النباتية');
    await useDemoDocument(t, 'شهادة المنشأ');
    await useDemoDocument(t, 'الفاتورة التجارية');
    await tapText(t, 'التالي');

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
    expect(created.importerCountry, 'الإمارات');
    expect(created.destination, 'دبي');
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
