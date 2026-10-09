import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_widgets.dart';
import '../../shared/repositories/mock_data.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController();
  String? _topic;
  bool _sending = false;

  static const _faq = [
    ('كيف أنشئ شحنة تصدير؟', 'من الرئيسية اضغط "تصدير" وأكمل الخطوات الخمس: المصدّر، المستورد، المنتج، النقل، ثم المراجعة والتأكيد.'),
    ('كيف يعمل فحص الذكاء الاصطناعي؟', 'ارفع صورة أو فيديو للمنتج، ثم اضغط "بدء التحليل". في النسخة التجريبية تُستخدم خدمة محاكاة توضيحية، ويمكن ربط نموذج Python عبر FastAPI من الإعدادات.'),
    ('ما الفرق بين النضج والتدهور؟', 'النضج هو تطوّر اللون والطراوة الطبيعي، والتدهور هو التلف (عفن، ذبول، ضرر البرد). المحاكاة تتابع كلًا منهما بشكل منفصل.'),
    ('ماذا يحدث عند عطل التبريد؟', 'ترتفع حرارة الحمولة تدريجيًا نحو حرارة الجو، فيرتفع معدل التلف وتظهر تنبيهات وتوصيات فورية.'),
    ('ما الوثائق المطلوبة للتسجيل؟', 'السجل التجاري، عضوية الغرفة، رخصة المهن، بالإضافة إلى وثائق حسب النشاط: شهادة تسجيل مصدّر للمصدّرين وموافقة استيراد الأغذية للمستوردين.'),
  ];

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _sending = false;
      _topic = null;
      _message.clear();
    });
    _form.currentState!.reset();
    Toast.success(context, 'تم استلام تذكرتك رقم #${DateTime.now().millisecondsSinceEpoch % 10000} (تجريبي)');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('المساعدة والدعم')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ResponsiveBody(
          maxWidth: 760,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppCard(
              color: AppColors.ice,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('بيانات الدخول التجريبية', style: t.titleSmall),
                const SizedBox(height: 4),
                SelectableText(
                  '${MockData.demoEmail} / ${MockData.demoPassword}\nرمز التحقق OTP: ${MockData.demoOtp}',
                ),
              ]),
            ),
            const SectionHeader('الأسئلة الشائعة', icon: Icons.help_outline),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final q in _faq)
                  ExpansionTile(
                    title: Text(q.$1, style: t.titleSmall),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(q.$2, style: t.bodyMedium)],
                  ),
              ]),
            ),
            const SectionHeader('تواصل معنا', icon: Icons.support_agent_outlined),
            AppCard(
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  AppDropdown<String>(
                    label: 'الموضوع',
                    items: const ['مشكلة في شحنة', 'التسجيل والتوثيق', 'فحص الذكاء الاصطناعي', 'المحاكاة', 'أخرى'],
                    value: _topic,
                    onChanged: (v) => setState(() => _topic = v),
                  ),
                  TextFormField(
                    controller: _message,
                    maxLines: 4,
                    maxLength: 500,
                    validator: (v) => (v == null || v.trim().length < 10) ? 'اكتب وصفًا لا يقل عن 10 أحرف' : Validators.required(v),
                    decoration: const InputDecoration(labelText: 'رسالتك', alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 8),
                  LoadingButton(label: 'إرسال', icon: Icons.send, loading: _sending, onPressed: _send),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            const AppCard(
              child: Column(children: [
                InfoRow(icon: Icons.phone_outlined, label: 'الهاتف', value: '+962 6 000 0000 (تجريبي)'),
                InfoRow(icon: Icons.email_outlined, label: 'البريد', value: 'support@freshroute.example'),
                InfoRow(icon: Icons.schedule, label: 'ساعات العمل', value: 'الأحد – الخميس، 9:00 – 17:00'),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
