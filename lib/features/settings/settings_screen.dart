import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../shared/repositories/notification_repository.dart';
import '../../shared/repositories/settings_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsRepository>();
    final t = Theme.of(context).textTheme;

    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: t.titleSmall?.copyWith(color: AppColors.primary))),
            AppCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Column(children: children)),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ResponsiveBody(
          maxWidth: 700,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            section('الإشعارات', [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('الإشعارات الفورية'),
                value: s.pushNotifications,
                onChanged: (v) {
                  s.update((x) => x.pushNotifications = v);
                  context.read<NotificationRepository>().enabled = v;
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تنبيهات الحرارة'),
                value: s.temperatureAlerts,
                onChanged: (v) => s.update((x) => x.temperatureAlerts = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تنبيهات الرطوبة'),
                value: s.humidityAlerts,
                onChanged: (v) => s.update((x) => x.humidityAlerts = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('حدّ تنبيه الحرارة'),
                subtitle: Text('تنبيه عند تجاوز نقطة الضبط بـ ${Fmt.temp(s.alertThresholdC)}'),
              ),
              Slider(
                value: s.alertThresholdC,
                min: 1,
                max: 6,
                divisions: 10,
                label: Fmt.temp(s.alertThresholdC),
                onChanged: (v) => s.update((x) => x.alertThresholdC = v),
              ),
            ]),
            section('المحاكاة', [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('سرعة الزمن في المحاكاة'),
                subtitle: Text('${s.simulationSpeed.toStringAsFixed(1)} ساعة محاكاة لكل ثانية (الرحلة ≈ ${(48 / s.simulationSpeed).round()} ثانية) — تُطبَّق على الرحلات الجديدة'),
              ),
              Slider(
                value: s.simulationSpeed,
                min: 0.25,
                max: 3,
                divisions: 11,
                label: s.simulationSpeed.toStringAsFixed(1),
                onChanged: (v) => s.update((x) => x.simulationSpeed = v),
              ),
            ]),
            section('عام', [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text('حول التطبيق'),
                trailing: const Text('v1.0.0 (تجريبي)'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'FreshRoute AI',
                  applicationVersion: '1.0.0 demo',
                  children: const [Text('منصة B2B للتجارة الزراعية والنقل المبرّد الذكي. جميع البيانات في هذه النسخة تجريبية.')],
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
