import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../shared/repositories/notification_repository.dart';
import '../../shared/repositories/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _url;

  @override
  void initState() {
    super.initState();
    // Created eagerly: a lazy field would first be read in dispose(), where context lookups are unsafe.
    _url = TextEditingController(text: context.read<SettingsRepository>().apiBaseUrl);
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

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
            section('محرّك فحص الذكاء الاصطناعي', [
              for (final e in AiEngine.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(s.aiEngine == e ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: AppColors.primary),
                  title: Text(e.label),
                  onTap: () => s.update((x) => x.aiEngine = e),
                ),
              if (s.aiEngine == AiEngine.fastApi) ...[
                TextField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(labelText: 'عنوان خادم FastAPI', helperText: 'Android emulator: http://10.0.2.2:8000 — Chrome: http://localhost:8000'),
                  onChanged: (v) => s.update((x) => x.apiBaseUrl = v.trim()),
                ),
                const SizedBox(height: 12),
              ],
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: InlineMessage(text: 'خدمة المحاكاة لا تشغّل أي نموذج وتُرجع نتائج توضيحية ثابتة. اختر FastAPI بعد تشغيل نموذجك.'),
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
