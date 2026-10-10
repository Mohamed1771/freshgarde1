import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/widgets/brand.dart';
import '../../shared/repositories/notification_repository.dart';
import '../marketplace/marketplace_screen.dart';
import '../profile/profile_screen.dart';
import '../shipments/my_shipments_screen.dart';
import 'home_screen.dart';

/// Main pages via bottom navigation (no side menu).
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _titles = {
    MainTab.home: 'الرئيسية',
    MainTab.marketplace: 'السوق',
    MainTab.shipments: 'شحناتي',
    MainTab.profile: 'حسابي',
  };

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final unread = context.watch<NotificationRepository>().unreadCount;

    return PopScope(
      canPop: shell.tab == MainTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.go(MainTab.home);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(children: [
            const BrandLogo(size: 32),
            const SizedBox(width: 10),
            Text(_titles[shell.tab]!),
          ]),
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
          children: const [HomeScreen(), MarketplaceScreen(), MyShipmentsScreen(), ProfileScreen()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.tab.index,
          onDestinationSelected: (i) => shell.go(MainTab.values[i]),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'السوق'),
            NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'شحناتي'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}
