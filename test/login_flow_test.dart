import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshroute_platform/app/app.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('splash → login with demo credentials → home dashboard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    await tester.pumpWidget(const FreshRouteApp());
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsWidgets);

    // Validation: empty submit shows errors.
    await tester.tap(find.text('دخول'));
    await tester.pump();
    expect(find.text('أدخل البريد الإلكتروني أو رقم الهاتف'), findsOneWidget);

    await tester.tap(find.text('تعبئة البيانات التجريبية'));
    await tester.pump();
    await tester.tap(find.text('دخول'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('استيراد'), findsOneWidget);
    expect(find.text('تصدير'), findsOneWidget);
    expect(find.text('العروض التجارية المتاحة'), findsOneWidget);
  });
}
