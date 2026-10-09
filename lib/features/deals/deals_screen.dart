import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/product_visual.dart';
import '../../shared/models/trading_offer.dart';
import '../../shared/repositories/deal_repository.dart';

Color dealStatusColor(DealStatus s) => switch (s) {
      DealStatus.pending => AppColors.warning,
      DealStatus.accepted => AppColors.success,
      DealStatus.rejected => AppColors.danger,
      DealStatus.cancelled => AppColors.textSecondary,
    };

/// Deals & Requests: outgoing purchase requests and incoming requests on my offers.
/// Used as a bottom-nav tab ([standalone] = false) and as a pushed route from notifications.
class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key, this.standalone = false});
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<DealRepository>();
    final body = DefaultTabController(
      length: 2,
      child: Column(children: [
        Material(
          color: AppColors.white,
          child: TabBar(tabs: [
            Tab(text: 'طلباتي (${repo.outgoing.length})'),
            Tab(text: 'طلبات واردة (${repo.incoming.length})'),
          ]),
        ),
        Expanded(
          child: TabBarView(children: [
            _DealList(
              deals: repo.outgoing,
              empty: EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'لم ترسل أي طلب بعد',
                message: 'تصفّح سوق الاستيراد وأرسل طلب صفقة.',
                actionLabel: 'تصفّح العروض',
                onAction: () {
                  context.read<ShellController>().openMarketplace();
                  if (standalone) Navigator.popUntil(context, ModalRoute.withName(Routes.home));
                },
              ),
            ),
            _DealList(deals: repo.incoming, empty: const EmptyState(icon: Icons.inbox_outlined, title: 'لا توجد طلبات واردة')),
          ]),
        ),
      ]),
    );
    return standalone ? Scaffold(appBar: AppBar(title: const Text('الصفقات والطلبات')), body: body) : body;
  }
}

class _DealList extends StatelessWidget {
  const _DealList({required this.deals, required this.empty});
  final List<DealRequest> deals;
  final Widget empty;

  @override
  Widget build(BuildContext context) => deals.isEmpty
      ? empty
      : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: deals.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => ResponsiveBody(child: _DealCard(deal: deals[i])),
        );
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.deal});
  final DealRequest deal;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final d = deal;
    final repo = context.read<DealRepository>();
    return AppCard(
      onTap: () => Navigator.pushNamed(context, Routes.offerDetails, arguments: d.offer.id),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ProductThumb(product: d.offer.product, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${d.id} • ${d.offer.title}', style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${d.incoming ? 'من' : 'إلى'}: ${d.counterparty}', style: t.bodySmall),
            ]),
          ),
          StatusChip(label: d.status.label, color: dealStatusColor(d.status), dense: true),
        ]),
        const Divider(height: 20),
        InfoRow(label: 'الكمية', value: Fmt.tons(d.quantityTons)),
        InfoRow(label: 'القيمة', value: Fmt.money(d.totalJod)),
        InfoRow(label: 'التسليم', value: '${d.deliveryCity} • ${Fmt.date(d.deliveryDate)}'),
        InfoRow(label: 'الدفع', value: d.paymentTerms),
        if (d.needsRefrigeratedTransport) const InfoRow(label: 'النقل', value: 'نقل مبرّد عبر FreshRoute'),
        if (d.notes.isNotEmpty) InfoRow(label: 'ملاحظات', value: d.notes),
        if (d.status == DealStatus.pending) ...[
          const SizedBox(height: 8),
          if (d.incoming)
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                  onPressed: () => repo.respond(d, DealStatus.rejected),
                  child: const Text('رفض'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () => repo.respond(d, DealStatus.accepted), child: const Text('قبول'))),
            ])
          else
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () async {
                  if (await confirmDialog(context, title: 'إلغاء الطلب', message: 'هل تريد إلغاء طلب الصفقة ${d.id}؟', destructive: true)) {
                    repo.respond(d, DealStatus.cancelled);
                  }
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('إلغاء الطلب'),
              ),
            ),
        ],
      ]),
    );
  }
}
