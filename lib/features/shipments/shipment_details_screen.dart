import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/product_visual.dart';
import '../../shared/models/shipment.dart';
import '../../shared/models/simulation_state.dart';
import '../../shared/repositories/shipment_repository.dart';
import '../simulation/live_simulation_service.dart';
import 'widgets/live_panels.dart';
import 'widgets/shipment_card.dart';

/// Live shipment view: the 3D simulation runs on its own (scenario-driven, no controls)
/// and every panel below follows it.
class ShipmentDetailsScreen extends StatefulWidget {
  const ShipmentDetailsScreen({super.key, this.shipmentId});

  /// When null, the first active shipment is shown.
  final String? shipmentId;

  @override
  State<ShipmentDetailsScreen> createState() => _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends State<ShipmentDetailsScreen> {
  Shipment? _shipment;
  LiveSession? _session;
  StreamSubscription<String>? _alertSub;

  @override
  void initState() {
    super.initState();
    final repo = context.read<ShipmentRepository>();
    _shipment = widget.shipmentId != null
        ? repo.byId(widget.shipmentId!)
        : (repo.byStatus(ShipmentStatus.active).firstOrNull ?? repo.all.firstOrNull);
    if (_shipment != null) {
      _session = context.read<LiveSimulationService>().sessionFor(_shipment!);
      _alertSub = _session!.newAlerts.listen(_showAlert);
    }
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  void _showAlert(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 4),
        content: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.white),
          const SizedBox(width: 10),
          Expanded(child: Text('تنبيه: $msg', style: const TextStyle(color: AppColors.white))),
        ]),
      ));
  }

  void _openCrate(SimulationState s) {
    _session!.bridge.inspectCrate(0);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => StreamBuilder<SimulationState>(
        stream: _session!.bridge.onSimulationStateChanged,
        initialData: s,
        builder: (c, snap) {
          final st = snap.data!;
          final t = Theme.of(c).textTheme;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('الصندوق 1 — الساعة ${st.hour.toStringAsFixed(1)}', style: t.titleLarge),
                const SizedBox(height: 12),
                ProduceAppearance(ripeness: st.ripeness, deterioration: st.deterioration, height: 180),
                const SizedBox(height: 12),
                InfoRow(label: 'المرحلة الحالية', value: st.stage.label, valueColor: st.stage.color),
                InfoRow(label: 'النضج', value: Fmt.pct(st.ripeness * 100)),
                InfoRow(label: 'التدهور', value: Fmt.pct(st.deterioration * 100)),
                InfoRow(label: 'حرارة الصندوق', value: Fmt.temp(st.cargoTempC)),
                const SizedBox(height: 8),
                const InlineMessage(
                  text: 'مظهر محاكى ناتج عن نموذج الحركية، وليس استدلالًا من نموذج ذكاء اصطناعي.',
                  color: AppColors.warning,
                  icon: Icons.science_outlined,
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ShipmentRepository>(); // rebuild on status / inspection / alert changes
    final s = _shipment;
    final session = _session;
    if (s == null || session == null) {
      return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.search_off, title: 'الشحنة غير موجودة'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('الشحنة ${s.id}'),
        actions: [_StatusMenu(shipment: s)],
      ),
      body: StreamBuilder<SimulationState>(
        stream: session.bridge.onSimulationStateChanged,
        initialData: session.state,
        builder: (context, snap) {
          final st = snap.data!;
          return LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 1000;
            final viewport = SizedBox(
              height: wide ? 460 : (c.maxWidth * 0.75).clamp(260.0, 380.0),
              child: LiveViewport(bridge: session.bridge, state: st, shipment: s),
            );
            final primary = <Widget>[
              viewport,
              if (s.status == ShipmentStatus.pending) ...[const SizedBox(height: 12), _PendingBanner(shipment: s)],
              const SizedBox(height: 12),
              LiveReadings(state: st, shipment: s),
              const SizedBox(height: 12),
              TripTimeline(state: st),
              const SizedBox(height: 12),
              TelemetryCharts(state: st),
              const SizedBox(height: 12),
              ProduceStateCard(state: st, onTap: () => _openCrate(st)),
              const SizedBox(height: 12),
              ArrivalForecastCard(state: st),
            ];
            final secondary = <Widget>[
              RecommendationsPanel(recommendations: st.recommendations),
              const SizedBox(height: 12),
              DecisionFeed(decisions: st.decisions),
              const SizedBox(height: 12),
              _InfoCard(shipment: s),
              const SizedBox(height: 12),
              _AlertsList(shipment: s),
            ];
            if (wide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: ListView(padding: const EdgeInsets.all(16), children: primary)),
                SizedBox(width: 440, child: ListView(padding: const EdgeInsets.fromLTRB(0, 16, 16, 16), children: secondary)),
              ]);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [ResponsiveBody(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...primary, const SizedBox(height: 12), ...secondary]))],
            );
          });
        },
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.shipment});
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: AppColors.warning.withValues(alpha: 0.08),
      child: Row(children: [
        const Icon(Icons.schedule, color: AppColors.warning),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('الشحنة بانتظار الانطلاق', style: t.titleSmall),
            Text('تبدأ المحاكاة المباشرة تلقائيًا عند انطلاق الشاحنة.', style: t.bodySmall),
          ]),
        ),
        FilledButton(
          onPressed: () => context.read<LiveSimulationService>().startTrip(shipment),
          child: const Text('انطلاق الشاحنة'),
        ),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.shipment});
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = shipment;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ProductThumb(product: s.product, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.product.name} — ${s.variety}', style: t.titleSmall),
              Text('${Fmt.tons(s.quantityTons)} • ${s.packaging}', style: t.bodySmall),
            ]),
          ),
          StatusChip(label: s.status.label, color: shipmentStatusColor(s.status), icon: s.status.icon, dense: true),
        ]),
        const Divider(height: 22),
        InfoRow(icon: Icons.qr_code_2, label: 'رقم الشحنة', value: s.id),
        InfoRow(icon: Icons.route_outlined, label: 'المسار', value: s.route),
        InfoRow(icon: Icons.flight_takeoff, label: 'الانطلاق', value: Fmt.dateTime(s.departure)),
        InfoRow(icon: Icons.flag_outlined, label: 'الوصول المتوقع', value: Fmt.dateTime(s.eta)),
        InfoRow(icon: Icons.upload_rounded, label: 'المصدّر', value: '${s.exporterCompany}\n${s.exporterName}'),
        InfoRow(icon: Icons.download_rounded, label: 'المستورد', value: '${s.importerCompany} (${s.importerGovernorate})\n${s.importerName}'),
        InfoRow(icon: Icons.local_shipping_outlined, label: 'الشاحنة', value: '${s.truckType} • ${s.truckPlate}'),
        InfoRow(icon: Icons.badge_outlined, label: 'السائق', value: s.driverName),
      ]),
    );
  }
}

class _AlertsList extends StatelessWidget {
  const _AlertsList({required this.shipment});
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = shipment;
    final repo = context.read<ShipmentRepository>();
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('التنبيهات (${s.alerts.length})', style: t.titleSmall)),
          if (s.alerts.isNotEmpty)
            TextButton(
              onPressed: () async {
                if (await confirmDialog(context, title: 'مسح التنبيهات', message: 'سيتم وضع جميع التنبيهات كمعالجة وإزالتها.')) {
                  repo.clearAlerts(s);
                }
              },
              child: const Text('مسح الكل'),
            ),
        ]),
        if (s.alerts.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(children: [Icon(Icons.check_circle_outline, color: AppColors.success), SizedBox(width: 10), Text('لا توجد تنبيهات')]),
          ),
        for (final a in s.alerts.take(8))
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(a.severity.icon, color: a.severity.color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.message, style: t.bodyMedium),
                  Text('${Fmt.ago(a.time)} • ${a.severity.label}${a.source == 'simulation' ? ' • من المحاكاة' : ''}', style: t.bodySmall),
                ]),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.shipment});
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final live = context.read<LiveSimulationService>();
    final s = shipment;
    final actions = <(String, IconData, ShipmentStatus)>[
      if (s.status == ShipmentStatus.pending) ('انطلاق الشاحنة', Icons.play_arrow, ShipmentStatus.active),
      if (s.status == ShipmentStatus.active) ('تأكيد التسليم', Icons.task_alt, ShipmentStatus.delivered),
      if (s.status == ShipmentStatus.delivered) ('أرشفة', Icons.inventory_2_outlined, ShipmentStatus.archived),
      if (s.status == ShipmentStatus.archived) ('استعادة من الأرشيف', Icons.unarchive_outlined, ShipmentStatus.delivered),
    ];
    return PopupMenuButton<ShipmentStatus>(
      tooltip: 'تحديث الحالة',
      onSelected: (st) async {
        if (!await confirmDialog(context, title: 'تحديث حالة الشحنة', message: 'تغيير الحالة إلى "${st.label}"؟')) return;
        st == ShipmentStatus.active ? live.startTrip(s) : live.setStatus(s, st);
        if (context.mounted) Toast.success(context, 'تم تحديث الحالة إلى ${st.label}');
      },
      itemBuilder: (_) => [
        for (final a in actions) PopupMenuItem(value: a.$3, child: ListTile(leading: Icon(a.$2), title: Text(a.$1), contentPadding: EdgeInsets.zero)),
      ],
    );
  }
}
