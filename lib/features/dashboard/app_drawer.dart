import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../shared/repositories/notification_repository.dart';

/// Navigation drawer for secondary pages. Every entry opens an implemented screen.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final trader = context.watch<AuthRepository>().currentTrader;
    final unread = context.watch<NotificationRepository>().unreadCount;
    final t = Theme.of(context).textTheme;

    void open(String route) {
      Navigator.pop(context);
      Navigator.pushNamed(context, route);
    }

    void tab(MainTab tab) {
      Navigator.pop(context);
      context.read<ShellController>().go(tab);
    }

    return Drawer(
      child: SafeArea(
        child: ListView(padding: EdgeInsets.zero, children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.sky,
                child: Text(trader?.initials ?? '؟', style: t.titleLarge?.copyWith(color: AppColors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(trader?.fullName ?? '', style: t.titleSmall?.copyWith(color: AppColors.white)),
                  Text(trader?.companyName ?? '', style: t.bodySmall?.copyWith(color: AppColors.ice), maxLines: 2, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),
          _Item(Icons.dashboard_outlined, 'الرئيسية', () => tab(MainTab.home)),
          _Item(Icons.add_box_outlined, 'إنشاء شحنة تصدير', () => open(Routes.createShipment)),
          _Item(Icons.document_scanner_outlined, 'فحص المنتج بالذكاء الاصطناعي', () => open(Routes.aiInspection)),
          _Item(Icons.view_in_ar_outlined, 'المتابعة المباشرة للشحنات', () => open(Routes.simulation)),
          _Item(Icons.notifications_none, 'الإشعارات', () => open(Routes.notifications), badge: unread),
          _Item(Icons.handshake_outlined, 'الصفقات والطلبات', () => tab(MainTab.deals)),
          _Item(Icons.bar_chart_rounded, 'التقارير', () => open(Routes.reports)),
          const Divider(),
          _Item(Icons.person_outline, 'الملف التجاري', () => tab(MainTab.profile)),
          _Item(Icons.settings_outlined, 'الإعدادات', () => open(Routes.settings)),
          _Item(Icons.support_agent_outlined, 'المساعدة والدعم', () => open(Routes.help)),
          const Divider(),
          _Item(Icons.logout, 'تسجيل الخروج', () async {
            final ok = await confirmDialog(context, title: 'تسجيل الخروج', message: 'هل تريد تسجيل الخروج من حسابك؟', confirm: 'خروج');
            if (!ok || !context.mounted) return;
            context.read<AuthRepository>().logout();
            Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
          }, color: AppColors.danger),
        ]),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.label, this.onTap, {this.badge = 0, this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
  final Color? color;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: color ?? AppColors.navy),
        title: Text(label, style: TextStyle(color: color)),
        trailing: badge > 0 ? Badge(label: Text('$badge')) : null,
        onTap: onTap,
      );
}
