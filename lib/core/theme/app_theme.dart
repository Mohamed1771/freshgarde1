import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Material 3 theme. Cairo for headings, IBM Plex Sans Arabic for body text.
abstract final class AppTheme {
  static const radius = 14.0;
  static const gap = 16.0;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.sky,
      surface: AppColors.white,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    );

    final body = GoogleFonts.ibmPlexSansArabicTextTheme();
    TextStyle? heading(TextStyle? s, double size, [FontWeight w = FontWeight.w700]) =>
        GoogleFonts.cairo(textStyle: s, fontSize: size, fontWeight: w, color: AppColors.textPrimary, height: 1.35);

    final textTheme = body
        .copyWith(
          headlineLarge: heading(body.headlineLarge, 28),
          headlineMedium: heading(body.headlineMedium, 24),
          headlineSmall: heading(body.headlineSmall, 20),
          titleLarge: heading(body.titleLarge, 20),
          titleMedium: heading(body.titleMedium, 17, FontWeight.w600),
          titleSmall: heading(body.titleSmall, 15, FontWeight.w600),
          bodyLarge: body.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
          bodyMedium: body.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
          bodySmall: body.bodySmall?.copyWith(fontSize: 13, color: AppColors.textSecondary),
          labelLarge: body.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary);

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: w));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: heading(null, 20),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(side: const BorderSide(color: AppColors.border)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(textStyle: textTheme.labelLarge)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.primary, 1.6),
        errorBorder: border(AppColors.danger),
        focusedErrorBorder: border(AppColors.danger, 1.6),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.ice,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: textTheme.bodyMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.ice,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.bodyMedium,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.white, shape: shape),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.white),
    );
  }
}
