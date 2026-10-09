import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centers content and caps its width on tablets / web.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 920});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16), this.color});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
        color: color,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.icon});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 22, color: AppColors.primary), const SizedBox(width: 8)],
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
          ],
        ),
      );
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color, this.icon, this.dense = false});
  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 2 : 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 15, color: color), const SizedBox(width: 4)],
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: dense ? 12 : 13)),
          ],
        ),
      );
}

/// Badge used everywhere a value is mock / simulated, so demo data is never mistaken for real data.
class MockBadge extends StatelessWidget {
  const MockBadge({super.key, this.label = 'بيانات تجريبية'});
  final String label;

  @override
  Widget build(BuildContext context) =>
      StatusChip(label: label, color: AppColors.warning, icon: Icons.science_outlined, dense: true);
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction});
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 36, backgroundColor: AppColors.ice, child: Icon(icon, size: 36, color: AppColors.primary)),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(message!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      );
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.icon, this.valueColor});
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[Icon(icon, size: 20, color: AppColors.textSecondary), const SizedBox(width: 10)],
          SizedBox(width: 130, child: Text(label, style: t.bodyMedium?.copyWith(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: valueColor))),
        ],
      ),
    );
  }
}

/// Compact KPI tile (temperature, humidity, quality...).
class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.icon, required this.label, required this.value, this.color = AppColors.primary, this.caption});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value, style: t.headlineSmall?.copyWith(color: color)),
          ),
          if (caption != null) Text(caption!, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Lays out tiles in a responsive grid (2 columns on phones, more on wide screens).
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.children, this.minTileWidth = 160, this.spacing = 12});
  final List<Widget> children;
  final double minTileWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = (c.maxWidth / minTileWidth).floor().clamp(2, 4);
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final ch in children) SizedBox(width: w, child: ch)],
        );
      });
}

/// Filled button that shows a spinner while [loading].
class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ]),
      );
}

class InlineMessage extends StatelessWidget {
  const InlineMessage({super.key, required this.text, this.color = AppColors.info, this.icon = Icons.info_outline});
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ]),
      );
}

abstract final class Toast {
  static void success(BuildContext context, String msg) => _show(context, msg, AppColors.success, Icons.check_circle_outline);
  static void error(BuildContext context, String msg) => _show(context, msg, AppColors.danger, Icons.error_outline);
  static void info(BuildContext context, String msg) => _show(context, msg, AppColors.sky, Icons.info_outline);

  static void _show(BuildContext context, String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Expanded(child: Text(msg))]),
      ));
  }
}

/// Confirmation dialog returning true when accepted.
Future<bool> confirmDialog(BuildContext context, {required String title, required String message, String confirm = 'تأكيد', bool destructive = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.danger) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return r ?? false;
}
