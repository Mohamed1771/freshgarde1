import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_controller.dart';
import '../../core/routing/routes.dart';
import '../../shared/repositories/deal_repository.dart';
import '../../shared/repositories/notification_repository.dart';
import '../deals/deals_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../profile/profile_screen.dart';
import '../shipments/my_shipments_screen.dart';
import 'app_drawer.dart';
import 'home_screen.dart';

/// Main pages via bottom navigation; secondary pages via the drawer.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _titles = {
    MainTab.home: 'الرئيسية',
    MainTab.marketplace: 'سوق الاستيراد',
    MainTab.shipments: 'شحناتي',
    MainTab.deals: 'الصفقات والطلبات',
    MainTab.profile: 'الملف التجاري',
  };

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final unread = context.watch<NotificationRepository>().unreadCount;
    final pendingDeals = context.watch<DealRepository>().pendingIncoming;

    return PopScope(
      canPop: shell.tab == MainTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.go(MainTab.home);
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text(_titles[shell.tab]!),
          actions: [
            IconButton(
              tooltip: 'الإشعارات',
              onPressed: () => Navigator.pushNamed(context, Routes.notifications),
              icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_none)),
            ),
            const SizedBox(width: 4),
          ],
        ),
        floatingActionButton: shell.tab == MainTab.shipments
            ? FloatingActionButton.extended(
                onPressed: () => Navigator.pushNamed(context, Routes.createShipment),
                icon: const Icon(Icons.add),
                label: const Text('شحنة جديدة'),
              )
            : null,
        body: IndexedStack(
          index: shell.tab.index,
          children: const [HomeScreen(), MarketplaceScreen(), MyShipmentsScreen(), DealsScreen(), ProfileScreen()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.tab.index,
          onDestinationSelected: (i) => shell.go(MainTab.values[i]),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
            const NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'السوق'),
            const NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'شحناتي'),
            NavigationDestination(
              icon: Badge(isLabelVisible: pendingDeals > 0, label: Text('$pendingDeals'), child: const Icon(Icons.handshake_outlined)),
              selectedIcon: const Icon(Icons.handshake),
              label: 'الصفقات',
            ),
            const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}
