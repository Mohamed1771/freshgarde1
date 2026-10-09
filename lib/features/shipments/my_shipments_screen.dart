import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../shared/models/shipment.dart';
import '../../shared/repositories/shipment_repository.dart';
import 'widgets/shipment_card.dart';

/// My Shipments with Active / Pending / Delivered / Archived tabs.
class MyShipmentsScreen extends StatefulWidget {
  const MyShipmentsScreen({super.key});

  @override
  State<MyShipmentsScreen> createState() => _MyShipmentsScreenState();
}

class _MyShipmentsScreenState extends State<MyShipmentsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final ShellController _shell;

  @override
  void initState() {
    super.initState();
    _shell = context.read<ShellController>();
    _tabs = TabController(length: ShipmentStatus.values.length, vsync: this, initialIndex: _shell.shipmentsTab.index);
    _shell.addListener(_syncTab);
  }

  void _syncTab() {
    if (_tabs.index != _shell.shipmentsTab.index) _tabs.animateTo(_shell.shipmentsTab.index);
  }

  @override
  void dispose() {
    _shell.removeListener(_syncTab);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ShipmentRepository>();
    return Column(children: [
      Material(
        color: AppColors.white,
        child: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          onTap: (i) => _shell.shipmentsTab = ShipmentStatus.values[i],
          tabs: [
            for (final s in ShipmentStatus.values) Tab(text: '${s.label} (${repo.byStatus(s).length})'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabs,
          children: [
            for (final s in ShipmentStatus.values) _list(repo.byStatus(s), s),
          ],
        ),
      ),
    ]);
  }

  Widget _list(List<Shipment> items, ShipmentStatus status) {
    if (items.isEmpty) {
      return EmptyState(
        icon: status.icon,
        title: 'لا توجد شحنات ${status.label}',
        message: status == ShipmentStatus.pending || status == ShipmentStatus.active ? 'أنشئ شحنة تصدير جديدة لتظهر هنا.' : null,
        actionLabel: status == ShipmentStatus.pending ? 'إنشاء شحنة' : null,
        onAction: () => Navigator.pushNamed(context, Routes.createShipment),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => ResponsiveBody(child: ShipmentCard(shipment: items[i])),
    );
  }
}
