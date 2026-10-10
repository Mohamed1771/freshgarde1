import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../shared/models/shipment.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../shared/repositories/offer_repository.dart';
import '../../shared/repositories/shipment_repository.dart';
import '../marketplace/widgets/offer_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final trader = context.watch<AuthRepository>().currentTrader;
    final shipments = context.watch<ShipmentRepository>();
    final offers = context.watch<OfferRepository>().all;
    final shell = context.read<ShellController>();
    final active = shipments.byStatus(ShipmentStatus.active);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ResponsiveBody(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('مرحبًا، ${trader?.fullName.split(' ').first ?? ''}', style: t.headlineMedium),
            Text('ماذا تريد أن تنجز اليوم؟', style: t.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.download_rounded,
                    title: 'استيراد',
                    subtitle: 'تصفّح العروض',
                    color: AppColors.secondaryDark,
                    onTap: () => shell.openMarketplace(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.upload_rounded,
                    title: 'تصدير',
                    subtitle: 'شحنة جديدة',
                    color: AppColors.navy,
                    onTap: () => Navigator.pushNamed(context, Routes.createShipment),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.local_shipping_rounded,
                    title: 'شحناتي',
                    subtitle: '${active.length} نشطة',
                    color: AppColors.primary,
                    onTap: () => shell.openShipments(ShipmentStatus.active),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            SectionHeader('العروض المتاحة', action: 'السوق', onAction: () => shell.openMarketplace()),
            OfferList(offers: offers),
          ]),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(radius: 24, backgroundColor: AppColors.white.withValues(alpha: 0.18), child: Icon(icon, color: AppColors.white, size: 26)),
            const SizedBox(height: 10),
            Text(title, style: t.titleMedium?.copyWith(color: AppColors.white)),
            Text(subtitle, style: t.bodySmall?.copyWith(color: AppColors.white.withValues(alpha: 0.85)), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
