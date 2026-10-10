import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../shared/models/shipment.dart';
import '../../shared/models/trader.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../shared/repositories/shipment_repository.dart';

/// Trader profile (bottom-nav tab).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trader = context.watch<AuthRepository>().currentTrader;
    final shipments = context.watch<ShipmentRepository>().all;
    if (trader == null) return const EmptyState(icon: Icons.person_off_outlined, title: 'لم يتم تسجيل الدخول');
    final t = Theme.of(context).textTheme;
    final verified = trader.status == VerificationStatus.verified;

    return ListView(padding: const EdgeInsets.all(16), children: [
      ResponsiveBody(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppCard(
            child: Column(children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                child: Text(trader.initials, style: t.headlineMedium?.copyWith(color: AppColors.white)),
              ),
              const SizedBox(height: 10),
              Text(trader.fullName, style: t.titleLarge),
              Text(trader.companyName, style: t.bodyMedium?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                StatusChip(
                  label: trader.status.label,
                  color: verified ? AppColors.success : AppColors.warning,
                  icon: verified ? Icons.verified : Icons.hourglass_top,
                ),
                StatusChip(label: trader.role.label, color: AppColors.primary, icon: Icons.swap_horiz),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          TileGrid(children: [
            MetricTile(icon: Icons.local_shipping_outlined, label: 'الشحنات', value: '${shipments.length}'),
            MetricTile(
              icon: Icons.check_circle_outline,
              label: 'تم تسليمها',
              value: '${shipments.where((s) => s.status == ShipmentStatus.delivered || s.status == ShipmentStatus.archived).length}',
              color: AppColors.success,
            ),
          ]),
          const SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('بيانات المنشأة', style: t.titleSmall),
              const SizedBox(height: 6),
              InfoRow(icon: Icons.email_outlined, label: 'البريد', value: trader.email),
              InfoRow(icon: Icons.phone_outlined, label: 'الهاتف', value: trader.phone),
              InfoRow(icon: Icons.location_city_outlined, label: 'المحافظة', value: trader.city),
              InfoRow(icon: Icons.business_outlined, label: 'الشكل القانوني', value: trader.businessType.label),
              InfoRow(icon: Icons.badge_outlined, label: 'السجل التجاري', value: trader.commercialRegNo),
              if (trader.establishmentNationalNo != null)
                InfoRow(icon: Icons.numbers, label: 'الرقم الوطني للمنشأة', value: trader.establishmentNationalNo!),
              if (trader.chamberMembershipNo != null)
                InfoRow(icon: Icons.card_membership_outlined, label: 'عضوية الغرفة', value: trader.chamberMembershipNo!),
              InfoRow(icon: Icons.event_outlined, label: 'تاريخ الانضمام', value: Fmt.date(trader.joinedAt)),
            ]),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('الوثائق (${trader.documents.length})', style: t.titleSmall),
              const SizedBox(height: 6),
              if (trader.documents.isEmpty) Text('لا توجد وثائق', style: t.bodyMedium),
              for (final d in trader.documents)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                  title: Text(d.type),
                  subtitle: Text('${d.fileName} • ${Fmt.date(d.uploadedAt)}'),
                  trailing: Icon(verified ? Icons.check_circle : Icons.hourglass_top, color: verified ? AppColors.success : AppColors.warning),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('الإعدادات'), trailing: const Icon(Icons.chevron_left), onTap: () => Navigator.pushNamed(context, Routes.settings)),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  if (!await confirmDialog(context, title: 'تسجيل الخروج', message: 'هل تريد تسجيل الخروج؟', confirm: 'خروج')) return;
                  if (!context.mounted) return;
                  context.read<AuthRepository>().logout();
                  Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
                },
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
