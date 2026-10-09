import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../shared/models/product.dart';
import '../../shared/models/shipment.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../shared/repositories/offer_repository.dart';
import '../../shared/repositories/shipment_repository.dart';
import '../marketplace/widgets/offer_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  ProductCategory? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openMarketplace() {
    context.read<ShellController>().openMarketplace(_search.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final trader = context.watch<AuthRepository>().currentTrader;
    final shipments = context.watch<ShipmentRepository>();
    final offers = context.watch<OfferRepository>().search(OfferFilter(category: _category)).take(6).toList();
    final shell = context.read<ShellController>();
    final active = shipments.byStatus(ShipmentStatus.active);
    final alerts = active.where((s) => s.hasUnresolvedCritical).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ResponsiveBody(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('مرحبًا، ${trader?.fullName.split(' ').first ?? ''} 👋', style: t.headlineMedium),
            Text('ماذا تريد أن تنجز اليوم؟', style: t.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _openMarketplace(),
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج، بائع أو وجهة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(tooltip: 'فلترة متقدمة', icon: const Icon(Icons.tune), onPressed: _openMarketplace),
              ),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.download_rounded,
                    title: 'استيراد',
                    subtitle: 'تصفّح العروض',
                    color: AppColors.primary,
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
                    color: AppColors.sky,
                    onTap: () => shell.openShipments(ShipmentStatus.active),
                  ),
                ),
              ]),
            ),
            if (alerts > 0) ...[
              const SizedBox(height: 14),
              AppCard(
                color: AppColors.danger.withValues(alpha: 0.06),
                onTap: () => shell.openShipments(ShipmentStatus.active),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(child: Text('$alerts شحنة نشطة لديها تنبيه حرارة حرج', style: t.titleSmall)),
                  const Icon(Icons.chevron_left),
                ]),
              ),
            ],
            const SizedBox(height: 14),
            AppCard(
              onTap: () => Navigator.pushNamed(context, Routes.aiInspection),
              child: Row(children: [
                const CircleAvatar(backgroundColor: AppColors.ice, child: Icon(Icons.document_scanner_outlined, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('فحص جودة المنتج بالذكاء الاصطناعي', style: t.titleSmall),
                    Text('ارفع صورة أو فيديو لتحديد مرحلة النضج والعيوب', style: t.bodySmall),
                  ]),
                ),
                const Icon(Icons.chevron_left),
              ]),
            ),
            const SizedBox(height: 8),
            SectionHeader('العروض التجارية المتاحة', action: 'عرض الكل', onAction: () => shell.openMarketplace()),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('الكل', _category == null, () => setState(() => _category = null)),
                for (final c in ProductCategory.values) _chip(c.label, _category == c, () => setState(() => _category = c)),
              ]),
            ),
            const SizedBox(height: 12),
            offers.isEmpty
                ? const EmptyState(icon: Icons.storefront_outlined, title: 'لا توجد عروض في هذا التصنيف')
                : OfferList(offers: offers),
          ]),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
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
