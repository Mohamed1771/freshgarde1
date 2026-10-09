import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/document_picker.dart';
import '../../core/widgets/form_widgets.dart';
import '../../shared/models/trader.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../shared/repositories/mock_data.dart';
import 'widgets/auth_scaffold.dart';

/// Required document definition. Conditions follow common Jordanian trade requirements.
class _DocReq {
  const _DocReq(this.key, this.label, {this.required = true, this.hint});
  final String key;
  final String label;
  final bool required;
  final String? hint;
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _steps = ['البيانات الشخصية', 'بيانات المنشأة', 'الوثائق', 'المراجعة'];
  final _forms = List.generate(2, (_) => GlobalKey<FormState>());
  int _step = 0;
  bool _loading = false;
  bool _docsError = false;
  bool _accepted = false;
  String? _error;

  // Personal
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  // Business
  final _company = TextEditingController();
  final _crNo = TextEditingController();
  final _estNo = TextEditingController();
  final _chamberNo = TextEditingController();
  TraderRole _role = TraderRole.exporter;
  BusinessType _type = BusinessType.individual;
  String? _city;
  // Documents: key -> picked file name
  final Map<String, String> _docs = {};

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _pass, _confirm, _company, _crNo, _estNo, _chamberNo]) {
      c.dispose();
    }
    super.dispose();
  }

  List<_DocReq> get _requiredDocs => [
        const _DocReq('cr', 'شهادة السجل التجاري', hint: 'صادرة عن وزارة الصناعة والتجارة والتموين'),
        const _DocReq('chamber', 'شهادة عضوية غرفة التجارة / الزراعة'),
        const _DocReq('license', 'رخصة المهن السارية', hint: 'صادرة عن البلدية / أمانة عمّان'),
        if (_type == BusinessType.company) const _DocReq('company', 'شهادة تسجيل الشركة', hint: 'دائرة مراقبة الشركات'),
        if (_role.canExport) const _DocReq('export', 'شهادة تسجيل مصدّر', hint: 'وزارة الزراعة — للصادرات الزراعية'),
        if (_role.canImport) const _DocReq('import', 'موافقة / رخصة استيراد مواد غذائية', hint: 'المؤسسة العامة للغذاء والدواء'),
        const _DocReq('tax', 'شهادة التسجيل في ضريبة المبيعات', required: false),
      ];

  bool _validateStep() {
    if (_step < 2) return _forms[_step].currentState!.validate();
    if (_step == 2) {
      final missing = _requiredDocs.where((d) => d.required && !_docs.containsKey(d.key));
      setState(() => _docsError = missing.isNotEmpty);
      if (missing.isNotEmpty) Toast.error(context, 'يرجى إرفاق ${missing.length} من الوثائق المطلوبة');
      return missing.isEmpty;
    }
    if (!_accepted) {
      Toast.error(context, 'يجب الموافقة على الشروط وسياسة الخصوصية');
      return false;
    }
    return true;
  }

  Future<void> _next() async {
    if (!_validateStep()) return;
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final docs = _requiredDocs.where((d) => _docs.containsKey(d.key));
    final trader = Trader(
      id: 'TR-${DateTime.now().millisecondsSinceEpoch % 100000}',
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      companyName: _company.text.trim(),
      role: _role,
      businessType: _type,
      city: _city!,
      commercialRegNo: _crNo.text.trim(),
      establishmentNationalNo: _estNo.text.trim().isEmpty ? null : _estNo.text.trim(),
      chamberMembershipNo: _chamberNo.text.trim(),
      documents: [for (final d in docs) UploadedDocument(type: d.label, fileName: _docs[d.key]!, uploadedAt: DateTime.now())],
    );
    try {
      await context.read<AuthRepository>().register(trader, _pass.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, Routes.verificationPending, (_) => false);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: AuthScaffold(
        title: 'تسجيل تاجر جديد',
        subtitle: 'أنشئ حساب منشأتك للتصدير والاستيراد',
        bottom: StepButtons(
          isFirst: _step == 0,
          isLast: _step == _steps.length - 1,
          loading: _loading,
          lastLabel: 'إرسال طلب التسجيل',
          onBack: () => setState(() => _step--),
          onNext: _next,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          StepProgress(steps: _steps, current: _step),
          const SizedBox(height: 20),
          if (_error != null) ...[
            InlineMessage(text: _error!, color: AppColors.danger, icon: Icons.error_outline),
            const SizedBox(height: 12),
          ],
          switch (_step) {
            0 => _personal(),
            1 => _business(),
            2 => _documents(),
            _ => _review(),
          },
        ]),
      ),
    );
  }

  Widget _personal() => Form(
        key: _forms[0],
        child: Column(children: [
          FieldGap(
            child: TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().split(RegExp(r'\s+')).length < 2) ? 'أدخل الاسم الكامل (اسمان على الأقل)' : null,
              decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline)),
            ),
          ),
          FieldGap(
            child: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined)),
            ),
          ),
          FieldGap(
            child: TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: Validators.jordanPhone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف', hintText: '07XXXXXXXX', prefixIcon: Icon(Icons.phone_outlined)),
            ),
          ),
          FieldGap(child: PasswordField(controller: _pass, validator: Validators.password, textInputAction: TextInputAction.next)),
          PasswordField(
            controller: _confirm,
            label: 'تأكيد كلمة المرور',
            validator: (v) => v != _pass.text ? 'كلمتا المرور غير متطابقتين' : null,
          ),
        ]),
      );

  Widget _business() {
    final t = Theme.of(context).textTheme;
    return Form(
      key: _forms[1],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FieldGap(
          child: TextFormField(
            controller: _company,
            validator: (v) => Validators.required(v, 'اسم المنشأة'),
            decoration: const InputDecoration(labelText: 'اسم المنشأة التجاري', prefixIcon: Icon(Icons.store_outlined)),
          ),
        ),
        Text('نوع النشاط', style: t.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<TraderRole>(
          segments: [for (final r in TraderRole.values) ButtonSegment(value: r, label: Text(r.label))],
          selected: {_role},
          onSelectionChanged: (s) => setState(() => _role = s.first),
        ),
        const SizedBox(height: 16),
        Text('الشكل القانوني', style: t.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<BusinessType>(
          segments: [for (final b in BusinessType.values) ButtonSegment(value: b, label: Text(b.label))],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
        ),
        const SizedBox(height: 16),
        AppDropdown<String>(
          label: 'المحافظة',
          icon: Icons.location_city_outlined,
          items: MockData.governorates,
          value: _city,
          onChanged: (v) => setState(() => _city = v),
        ),
        FieldGap(
          child: TextFormField(
            controller: _crNo,
            keyboardType: TextInputType.number,
            validator: (v) => Validators.digits(v, min: 4, max: 8, field: 'رقم السجل التجاري'),
            decoration: const InputDecoration(labelText: 'رقم السجل التجاري', prefixIcon: Icon(Icons.badge_outlined)),
          ),
        ),
        FieldGap(
          child: TextFormField(
            controller: _estNo,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (_type == BusinessType.individual && (v == null || v.trim().isEmpty)) return null;
              return Validators.digits(v, min: 9, field: 'الرقم الوطني للمنشأة');
            },
            decoration: InputDecoration(
              labelText: 'الرقم الوطني للمنشأة${_type == BusinessType.company ? '' : ' (اختياري)'}',
              helperText: _type == BusinessType.company ? 'مطلوب للشركات — 9 أرقام' : 'إن وُجد',
              prefixIcon: const Icon(Icons.numbers),
            ),
          ),
        ),
        TextFormField(
          controller: _chamberNo,
          keyboardType: TextInputType.number,
          validator: (v) => Validators.digits(v, min: 3, max: 8, field: 'رقم العضوية'),
          decoration: const InputDecoration(labelText: 'رقم عضوية غرفة التجارة / الزراعة', prefixIcon: Icon(Icons.card_membership_outlined)),
        ),
      ]),
    );
  }

  Widget _documents() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const InlineMessage(
          text: 'الوثائق المطلوبة تتغيّر حسب نوع النشاط والشكل القانوني. في النسخة التجريبية يُحفظ اسم الملف فقط ولا تُطلب صورة الهوية الشخصية.',
        ),
        const SizedBox(height: 14),
        for (final d in _requiredDocs)
          FilePickTile(
            label: d.label,
            hint: d.hint,
            required: d.required,
            fileName: _docs[d.key],
            showError: _docsError,
            onPick: () async {
              final name = await pickDocument(context, demoName: 'demo_${d.key}.pdf');
              if (name != null) setState(() => _docs[d.key] = name);
            },
            onClear: () => setState(() => _docs.remove(d.key)),
          ),
      ]);

  Widget _review() {
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('البيانات الشخصية', style: t.titleSmall),
          InfoRow(label: 'الاسم', value: _name.text),
          InfoRow(label: 'البريد', value: _email.text),
          InfoRow(label: 'الهاتف', value: _phone.text),
        ]),
      ),
      const SizedBox(height: 12),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('المنشأة', style: t.titleSmall),
          InfoRow(label: 'الاسم التجاري', value: _company.text),
          InfoRow(label: 'النشاط', value: _role.label),
          InfoRow(label: 'الشكل القانوني', value: _type.label),
          InfoRow(label: 'المحافظة', value: _city ?? '-'),
          InfoRow(label: 'السجل التجاري', value: _crNo.text),
          if (_estNo.text.isNotEmpty) InfoRow(label: 'الرقم الوطني', value: _estNo.text),
          InfoRow(label: 'الوثائق المرفقة', value: '${_docs.length} ملف'),
        ]),
      ),
      const SizedBox(height: 12),
      CheckboxListTile(
        value: _accepted,
        onChanged: (v) => setState(() => _accepted = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: const Text('أوافق على شروط الاستخدام وسياسة الخصوصية، وأقرّ بصحة البيانات المدخلة.'),
      ),
    ]);
  }
}
