import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_visual.dart';
import '../../../core/widgets/sparkline.dart';
import '../../../shared/models/cooling_recommendation.dart';
import '../../../shared/models/shipment.dart';
import '../../../shared/models/simulation_scenario.dart';
import '../../../shared/models/simulation_state.dart';
import '../../simulation/scene/scene_viewport.dart';
import '../../simulation/simulation_bridge.dart';

/// Panels of the live shipment view. All values come from [SimulationState] and update as the trip runs.

/// 3D scene with a live overlay: status, simulated clock, scenario, active event and trip progress.
class LiveViewport extends StatelessWidget {
  const LiveViewport({super.key, required this.bridge, required this.state, required this.shipment});
  final SimulationBridge bridge;
  final SimulationState state;
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final active = s.activeEvents;
    final (statusText, statusColor) = switch (shipment.status) {
      ShipmentStatus.pending => ('بانتظار الانطلاق', AppColors.warning),
      ShipmentStatus.active => (s.finished ? 'وصلت' : 'مباشر', s.finished ? AppColors.success : const Color(0xFFFF5A5A)),
      _ => ('رحلة مكتملة', AppColors.success),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(fit: StackFit.expand, children: [
        SceneViewport(onReady: bridge.attachScene, onClosed: bridge.detachScene),
        // Top overlay
        PositionedDirectional(
          top: 12,
          start: 12,
          end: 12,
          child: IgnorePointer(
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              _Pill(text: statusText, dot: statusColor, pulse: s.playing),
              _Pill(text: 'الساعة ${s.hour.toStringAsFixed(1)} / ${s.tripHours.toInt()}'),
              _Pill(text: s.scenario.label, icon: Icons.route),
              if (!s.sceneConnected) const _Pill(text: 'جارٍ تحميل المشهد…'),
            ]),
          ),
        ),
        // Bottom overlay: active event + trip progress
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.navy.withValues(alpha: 0.85)],
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                for (final e in active.take(2))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Icon(e.kind.icon, size: 18, color: e.kind.color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e.description,
                            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ),
                Row(children: [
                  Text(shipment.origin, style: const TextStyle(color: AppColors.ice, fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.progress,
                        minHeight: 6,
                        color: AppColors.sky,
                        backgroundColor: AppColors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(shipment.destination, style: const TextStyle(color: AppColors.ice, fontSize: 12)),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Pill extends StatefulWidget {
  const _Pill({required this.text, this.dot, this.icon, this.pulse = false});
  final String text;
  final Color? dot;
  final IconData? icon;
  final bool pulse;

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Pill old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.pulse && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AppColors.navy.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (widget.dot != null) ...[
            FadeTransition(
              opacity: widget.pulse ? Tween(begin: 0.35, end: 1.0).animate(_c) : const AlwaysStoppedAnimation(1),
              child: Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.dot, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 6),
          ],
          if (widget.icon != null) ...[Icon(widget.icon, size: 14, color: AppColors.sky), const SizedBox(width: 4)],
          Text(widget.text, style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
}

/// Live readings with a trend arrow from the last half-hour.
class LiveReadings extends StatelessWidget {
  const LiveReadings({super.key, required this.state, required this.shipment});
  final SimulationState state;
  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final h = s.history;
    String trend(double now, double? prev, {double eps = 0.15}) {
      if (prev == null || (now - prev).abs() < eps) return 'مستقر';
      return now > prev ? '▲ يرتفع' : '▼ ينخفض';
    }

    final prev = h.length >= 2 ? h[h.length - 2] : null;
    final tempAlarm = s.cargoTempC - s.setpointC > 3;
    final cond = CargoCondition.fromQuality(s.qualityPct);
    return TileGrid(minTileWidth: 150, children: [
      MetricTile(
        icon: Icons.thermostat,
        label: 'حرارة الحمولة',
        value: Fmt.temp(s.cargoTempC),
        color: tempAlarm ? AppColors.danger : AppColors.primary,
        caption: '${trend(s.cargoTempC, prev?.temperatureC)} • الخارج ${Fmt.temp(s.outsideTempC)}',
      ),
      MetricTile(
        icon: Icons.water_drop_outlined,
        label: 'الرطوبة',
        value: Fmt.pct(s.humidityPct),
        color: s.humidityPct < 85 ? AppColors.warning : AppColors.sky,
        caption: '${trend(s.humidityPct, prev?.humidityPct, eps: 0.5)} • الموصى ${Fmt.pct(shipment.product.optimalHumidity)}',
      ),
      MetricTile(
        icon: Icons.ac_unit,
        label: 'نقطة الضبط (AI)',
        value: Fmt.temp(s.setpointC),
        color: AppColors.navy,
        caption: s.coolingFailure ? 'وحدة التبريد متوقفة' : 'يضبطها نظام القرار',
      ),
      MetricTile(icon: Icons.health_and_safety_outlined, label: 'الجودة الحالية', value: Fmt.pct(s.qualityPct), color: cond.color, caption: cond.label),
    ]);
  }
}

/// Scenario timeline: event segments along the 48 h trip with the current position.
class TripTimeline extends StatelessWidget {
  const TripTimeline({super.key, required this.state});
  final SimulationState state;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = state;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.timeline, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('مسار الرحلة', style: t.titleSmall)),
          const MockBadge(label: 'سيناريو محاكاة'),
        ]),
        const SizedBox(height: 4),
        Text('${s.scenario.label}: ${s.scenario.description}', style: t.bodySmall),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          double x(double h) => (h / s.tripHours).clamp(0.0, 1.0) * w;
          return SizedBox(
            height: 30,
            child: Stack(clipBehavior: Clip.none, children: [
              PositionedDirectional(
                start: 0,
                end: 0,
                top: 11,
                child: Container(height: 8, decoration: BoxDecoration(color: AppColors.ice, borderRadius: BorderRadius.circular(4))),
              ),
              PositionedDirectional(
                start: 0,
                top: 11,
                child: Container(width: x(s.hour), height: 8, decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(4))),
              ),
              for (final e in s.events)
                PositionedDirectional(
                  start: x(e.start),
                  top: 9,
                  child: Container(
                    width: (x(e.end) - x(e.start)).clamp(6.0, w),
                    height: 12,
                    decoration: BoxDecoration(color: e.kind.color.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              PositionedDirectional(
                start: (x(s.hour) - 9).clamp(-9.0, w - 9),
                top: 0,
                child: Container(
                  width: 18,
                  height: 30,
                  alignment: Alignment.center,
                  child: Container(width: 4, height: 30, decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(2))),
                ),
              ),
            ]),
          );
        }),
        const SizedBox(height: 6),
        Row(children: [
          Text('الانطلاق', style: t.bodySmall),
          const Spacer(),
          Text('الوصول (48 س)', style: t.bodySmall),
        ]),
        const Divider(height: 22),
        for (final e in s.events) _eventRow(context, e),
      ]),
    );
  }

  Widget _eventRow(BuildContext context, TripEvent e) {
    final t = Theme.of(context).textTheme;
    final s = state;
    final (label, color) = e.activeAt(s.hour)
        ? ('جارٍ الآن', AppColors.danger)
        : s.hour >= e.end
            ? ('انتهى', AppColors.success)
            : ('قادم', AppColors.textMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        CircleAvatar(radius: 15, backgroundColor: e.kind.color.withValues(alpha: 0.14), child: Icon(e.kind.icon, size: 17, color: e.kind.color)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.description, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text('من الساعة ${e.start.toStringAsFixed(1)} إلى ${e.end.toStringAsFixed(1)}', style: t.bodySmall),
          ]),
        ),
        StatusChip(label: label, color: color, dense: true),
      ]),
    );
  }
}

/// Temperature and humidity history of the simulated trip so far.
class TelemetryCharts extends StatelessWidget {
  const TelemetryCharts({super.key, required this.state});
  final SimulationState state;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = state;
    final tempAlarm = s.cargoTempC - s.setpointC > 3;
    Widget chart(String title, String now, Widget spark) => AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(title, style: t.titleSmall)),
              Text(now, style: t.titleSmall?.copyWith(color: AppColors.primary)),
            ]),
            const SizedBox(height: 10),
            spark,
            const SizedBox(height: 4),
            Row(children: [Text('0 س', style: t.bodySmall), const Spacer(), Text('الآن', style: t.bodySmall)]),
          ]),
        );
    return LayoutBuilder(builder: (context, c) {
      final temp = chart(
        'حرارة الحمولة',
        Fmt.temp(s.cargoTempC),
        Sparkline(
          values: [...s.history.map((h) => h.temperatureC), s.cargoTempC],
          reference: s.setpointC,
          color: tempAlarm ? AppColors.danger : AppColors.primary,
        ),
      );
      final hum = chart(
        'الرطوبة',
        Fmt.pct(s.humidityPct),
        Sparkline(values: [...s.history.map((h) => h.humidityPct), s.humidityPct], color: AppColors.sky, minSpan: 10),
      );
      if (c.maxWidth < 560) return Column(children: [temp, const SizedBox(height: 12), hum]);
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: temp),
        const SizedBox(width: 12),
        Expanded(child: hum),
      ]);
    });
  }
}

/// Simulated produce appearance + separate ripeness / deterioration bars.
class ProduceStateCard extends StatelessWidget {
  const ProduceStateCard({super.key, required this.state, this.onTap});
  final SimulationState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = state;
    final source = s.appearanceSource == AppearanceSource.aiInspection
        ? 'بدأت من "${s.initialStage.label}" ${s.inspectionWasSimulated ? '(فحص محاكى)' : '(فحص نموذج AI)'}'
        : 'بدأت من "${s.initialStage.label}" — قيمة افتراضية، لم يُطبَّق فحص';
    return AppCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('حالة المنتج', style: t.titleSmall)),
          StatusChip(label: s.stage.label, color: s.stage.color, dense: true),
        ]),
        const SizedBox(height: 2),
        Text(source, style: t.bodySmall),
        const SizedBox(height: 10),
        ProduceAppearance(ripeness: s.ripeness, deterioration: s.deterioration, height: 110),
        const SizedBox(height: 4),
        Text('مظهر محاكى من النموذج — ليس استدلال AI', style: t.bodySmall?.copyWith(color: AppColors.warning)),
        const SizedBox(height: 8),
        _bar(context, 'النضج', s.ripeness, const Color(0xFFEA8C2C)),
        _bar(context, 'التدهور', s.deterioration, AppColors.danger),
      ]),
    );
  }

  Widget _bar(BuildContext context, String label, double v, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(width: 60, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: v.clamp(0, 1), minHeight: 10, color: c, backgroundColor: AppColors.ice),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 44, child: Text(Fmt.pct(v * 100), style: Theme.of(context).textTheme.bodySmall)),
        ]),
      );
}

class ArrivalForecastCard extends StatelessWidget {
  const ArrivalForecastCard({super.key, required this.state});
  final SimulationState state;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = state;
    final cond = CargoCondition.fromQuality(s.predictedArrivalQualityPct);
    Widget kv(String k, String v, [Color? c]) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: t.bodySmall),
            Text(v, style: t.titleSmall?.copyWith(color: c)),
          ]),
        );
    return AppCard(
      color: cond.color.withValues(alpha: 0.06),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.flag_circle_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(s.finished ? 'الحالة عند الوصول' : 'الحالة المتوقعة عند الوصول', style: t.titleSmall)),
          StatusChip(label: cond.label, color: cond.color, dense: true),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          kv('الجودة', Fmt.pct(s.predictedArrivalQualityPct)),
          kv('المرحلة', s.predictedArrivalStage.label, s.predictedArrivalStage.color),
          kv('التدهور', Fmt.pct(s.predictedArrivalDeterioration * 100)),
        ]),
        if (!s.finished) ...[
          const SizedBox(height: 6),
          Text('بافتراض استمرار الظروف الحالية والأحداث المجدولة في السيناريو.', style: t.bodySmall),
        ],
      ]),
    );
  }
}

class RecommendationsPanel extends StatelessWidget {
  const RecommendationsPanel({super.key, required this.recommendations});
  final List<CoolingRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('توصيات التبريد', style: t.titleSmall),
        ]),
        const SizedBox(height: 6),
        for (final r in recommendations) _tile(context, r),
      ]),
    );
  }

  Widget _tile(BuildContext context, CoolingRecommendation rec) {
    final t = Theme.of(context).textTheme;
    final c = switch (rec.priority) {
      RecommendationPriority.urgent => AppColors.danger,
      RecommendationPriority.advisory => AppColors.warning,
      RecommendationPriority.info => AppColors.success,
    };
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: BorderDirectional(start: BorderSide(color: c, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(rec.title, style: t.titleSmall)),
          StatusChip(label: rec.priority.label, color: c, dense: true),
        ]),
        const SizedBox(height: 2),
        Text(rec.detail, style: t.bodySmall),
      ]),
    );
  }
}

class DecisionFeed extends StatefulWidget {
  const DecisionFeed({super.key, required this.decisions});
  final List<AiDecisionLog> decisions;

  @override
  State<DecisionFeed> createState() => _DecisionFeedState();
}

class _DecisionFeedState extends State<DecisionFeed> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final items = widget.decisions.reversed.toList();
    final shown = _all ? items : items.take(4).toList();
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.psychology_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('قرارات نظام التبريد الذكي', style: t.titleSmall)),
          Text('${items.length}', style: t.bodySmall),
        ]),
        Text('فحص كل 3 ساعات — قواعد محاكاة وليست نموذج AI مدرّبًا', style: t.bodySmall),
        const SizedBox(height: 8),
        if (items.isEmpty) Text('لا توجد قرارات بعد.', style: t.bodyMedium),
        for (final d in shown) _row(context, d),
        if (items.length > 4)
          TextButton(onPressed: () => setState(() => _all = !_all), child: Text(_all ? 'عرض أقل' : 'عرض كل القرارات')),
      ]),
    );
  }

  Widget _row(BuildContext context, AiDecisionLog d) {
    final t = Theme.of(context).textTheme;
    final (icon, color) = switch (d.kind) {
      DecisionKind.change => (Icons.swap_vert, AppColors.primary),
      DecisionKind.hold => (Icons.check_circle_outline, AppColors.textSecondary),
      DecisionKind.alert => (Icons.warning_amber_rounded, AppColors.danger),
    };
    final head = switch (d.kind) {
      DecisionKind.change => '${Fmt.temp(d.fromSetpoint)} ← ${Fmt.temp(d.toSetpoint)}',
      DecisionKind.hold => 'إبقاء ${Fmt.temp(d.toSetpoint)}',
      DecisionKind.alert => 'تنبيه عطل',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(color: AppColors.ice, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text('س ${d.hour.toStringAsFixed(0)}', style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy)),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(head, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
            Text('${d.reason} (ثقة ${Fmt.pct(d.confidence * 100)})', style: t.bodySmall),
          ]),
        ),
      ]),
    );
  }
}
