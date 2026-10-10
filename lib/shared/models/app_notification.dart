import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum NotificationType {
  shipment('شحنة', Icons.local_shipping_outlined, AppColors.primary),
  alert('تنبيه', Icons.warning_amber_rounded, AppColors.danger),
  inspection('فحص AI', Icons.document_scanner_outlined, AppColors.sky),
  system('النظام', Icons.notifications_none, AppColors.textSecondary);

  const NotificationType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.shipmentId,
    this.read = false,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? shipmentId;
  bool read;
  final DateTime time;
}
