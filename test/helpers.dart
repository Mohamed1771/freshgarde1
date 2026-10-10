import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshroute_platform/app/app.dart';
import 'package:freshroute_platform/shared/repositories/mock_data.dart';

/// Shared helpers for the UI journey tests.

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

/// Launches the app on a large surface and signs in with the demo account.
Future<void> launchAndLogin(WidgetTester t) async {
  await t.binding.setSurfaceSize(const Size(1000, 1800));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(const FreshRouteApp());
  await settle(t, 1700);
  await t.enterText(find.byType(TextFormField).at(0), MockData.demoEmail);
  await t.enterText(find.byType(TextFormField).at(1), MockData.demoPassword);
  await tapText(t, 'دخول');
  await settle(t);
}

/// Fills the product and transport steps of the export wizard (shared by both receiver paths).
Future<void> fillProductAndTransport(WidgetTester t) async {
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
  await pickDate(t, 'تاريخ الانطلاق');
  await useDemoDocument(t, 'شهادة الصحة النباتية');
  await useDemoDocument(t, 'شهادة المنشأ');
  await useDemoDocument(t, 'الفاتورة التجارية');
  await tapText(t, 'التالي');
}
