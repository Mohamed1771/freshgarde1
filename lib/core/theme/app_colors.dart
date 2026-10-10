import 'package:flutter/material.dart';

/// Brand palette derived from the FreshRoute logo: leaf green → teal → cyan → deep blue.
abstract final class AppColors {
  static const navy = Color(0xFF0B3B5E);
  static const primary = Color(0xFF1279C6);
  static const sky = Color(0xFF1EB6E3);
  static const secondary = Color(0xFF2DB866);
  static const secondaryDark = Color(0xFF128A6A);
  static const ice = Color(0xFFE8F6F4);
  static const white = Color(0xFFFFFFFF);

  static const background = Color(0xFFF4F9F8);
  static const border = Color(0xFFD6E8E5);
  static const textPrimary = navy;
  static const textSecondary = Color(0xFF5F7280);
  static const textMuted = Color(0xFF95A6B0);

  static const success = Color(0xFF1F9E62);
  static const warning = Color(0xFFE09B1B);
  static const danger = Color(0xFFD64545);
  static const info = sky;

  /// The logo's gradient, used for brand surfaces (splash).
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4CD06A), Color(0xFF13B3A0), Color(0xFF1EB6E3), Color(0xFF1270C0)],
  );
}
