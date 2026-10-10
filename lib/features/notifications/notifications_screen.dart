import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../shared/models/app_notification.dart';
import '../../shared/repositories/notification_repository.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<NotificationRepository>();
    final items = repo.items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (repo.unreadCount > 0) TextButton(onPressed: repo.markAllRead, child: const Text('تعليم الكل كمقروء')),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(icon: Icons.notifications_off_outlined, title: 'لا توجد إشعارات', message: 'ستظهر هنا تنبيهات الشحنات والصفقات.')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = items[i];
                return ResponsiveBody(
                  child: Dismissible(
                    key: ValueKey(n.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: AlignmentDirectional.centerEnd,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.delete_outline, color: AppColors.white),
                    ),
                    onDismissed: (_) {
                      repo.remove(n);
                      Toast.info(context, 'تم حذف الإشعار');
                    },
                    child: _NotificationTile(n: n),
                  ),
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n});
  final AppNotification n;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: n.read ? null : AppColors.ice,
      padding: const EdgeInsets.all(12),
      onTap: () {
        context.read<NotificationRepository>().markRead(n);
        _showDetails(context, n);
      },
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: n.type.color.withValues(alpha: 0.12), child: Icon(n.type.icon, color: n.type.color)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(n.title, style: t.titleSmall)),
              if (!n.read) const CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
            ]),
            const SizedBox(height: 2),
            Text(n.body, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('${n.type.label} • ${Fmt.ago(n.time)}', style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
          ]),
        ),
      ]),
    );
  }

  static void _showDetails(BuildContext context, AppNotification n) {
    final t = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(n.type.icon, color: n.type.color),
              const SizedBox(width: 8),
              StatusChip(label: n.type.label, color: n.type.color, dense: true),
              const Spacer(),
              Text(Fmt.dateTime(n.time), style: t.bodySmall),
            ]),
            const SizedBox(height: 12),
            Text(n.title, style: t.titleLarge),
            const SizedBox(height: 8),
            Text(n.body, style: t.bodyLarge),
            const SizedBox(height: 20),
            if (n.shipmentId != null)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(c);
                  Navigator.pushNamed(context, Routes.shipmentDetails, arguments: n.shipmentId);
                },
                icon: const Icon(Icons.local_shipping_outlined),
                label: Text('عرض الشحنة ${n.shipmentId}'),
              )
            else
              OutlinedButton(onPressed: () => Navigator.pop(c), child: const Text('إغلاق')),
          ]),
        ),
      ),
    );
  }
}
