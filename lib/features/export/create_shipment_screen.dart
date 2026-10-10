import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/document_picker.dart';
import '../../core/widgets/form_widgets.dart';
import '../../core/widgets/product_visual.dart';
import '../../shared/models/inspection_result.dart';
import '../../shared/models/product.dart';
import '../../shared/models/sensor_reading.dart';
import '../../shared/models/shipment.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../shared/repositories/mock_data.dart';
import '../../shared/repositories/shipment_repository.dart';

/// Multi-step export shipment wizard. Submitting adds the shipment to the in-memory repository.
class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  static const _steps = ['المصدّر', 'المستورد', 'المنتج', 'النقل', 'المراجعة'];
  final _forms = List.generate(4, (_) => GlobalKey<FormState>());
  int _step = 0;
  bool _loading = false;
  bool _confirmed = false;
  bool _docsError = false;

  // Exporter
  late final _expName = TextEditingController();
  late final _expCompany = TextEditingController();
  late final _expPhone = TextEditingController();
  late final _expCr = TextEditingController();
  // Importer
  final _impName = TextEditingController();
  final _impCompany = TextEditingController();
  final _impPhone = TextEditingController();
  final _impAddress = TextEditingController();
  String? _impGovernorate;
  // Product
  Product? _product;
  final _variety = TextEditingController();
  final _qty = TextEditingController();
  String? _packaging;
  String _grade = 'درجة أولى';
  DateTime? _harvest;
  final List<String> _productImages = [];
  // Transport
  String? _truckType;
  final _plate = TextEditingController();
  final _driver = TextEditingController();
  final _driverPhone = TextEditingController();
  String? _origin;
  String? _destination;
  DateTime? _departure;
  DateTime? _arrival;
  double _setpoint = 12;
  bool _smartCooling = true;
  final Map<String, String> _docs = {};

  @override
  void initState() {
    super.initState();
    final t = context.read<AuthRepository>().currentTrader;
    _expName.text = t?.fullName ?? '';
    _expCompany.text = t?.companyName ?? '';
    _expPhone.text = t?.phone ?? '';
    _expCr.text = t?.commercialRegNo ?? '';
  }

  @override
  void dispose() {
    for (final c in [_expName, _expCompany, _expPhone, _expCr, _impName, _impCompany, _impPhone, _impAddress, _variety, _qty, _plate, _driver, _driverPhone]) {
      c.dispose();
    }
    super.dispose();
  }

  static const _requiredDocs = {
    'phyto': 'شهادة الصحة النباتية',
    'origin': 'شهادة المنشأ',
    'invoice': 'الفاتورة التجارية',
  };

  bool _validate() {
    if (_step < 4) {
      final ok = _forms[_step].currentState!.validate();
      if (_step == 3) {
        setState(() => _docsError = _docs.length < _requiredDocs.length);
        if (_docsError) {
          Toast.error(context, 'يرجى إرفاق مستندات الشحن المطلوبة');
          return false;
        }
      }
      return ok;
    }
    if (!_confirmed) {
      Toast.error(context, 'يرجى تأكيد صحة بيانات الشحنة');
      return false;
    }
    return true;
  }

  Future<void> _next() async {
    if (!_validate()) return;
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      return;
    }
    setState(() => _loading = true);
    final repo = context.read<ShipmentRepository>();
    final p = _product!;
    final shipment = Shipment(
      id: repo.nextId(),
      exporterName: _expName.text.trim(),
      exporterCompany: _expCompany.text.trim(),
      importerName: _impName.text.trim(),
      importerCompany: _impCompany.text.trim(),
      importerGovernorate: _impGovernorate!,
      product: p,
      variety: _variety.text.trim(),
      quantityTons: double.parse(_qty.text),
      packaging: _packaging!,
      origin: _origin!,
      destination: _destination!,
      departure: _departure!,
      eta: _arrival!,
      status: ShipmentStatus.pending,
      truckType: _truckType!,
      truckPlate: _plate.text.trim(),
      driverName: _driver.text.trim(),
      coolingSetpointC: _setpoint,
      smartCooling: _smartCooling,
      reading: SensorReading(time: DateTime.now(), temperatureC: _setpoint, humidityPct: p.optimalHumidity, setpointC: _setpoint),
      qualityPct: 95,
      forecast: QualityForecast(arrivalQualityPct: 90, shelfLifeDays: 8, arrivalStage: MaturityStage.turning, basis: 'تقدير أولي'),
    );
    await repo.create(shipment);
    if (!mounted) return;
    setState(() => _loading = false);

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 52),
        title: Text('تم إنشاء الشحنة ${shipment.id}'),
        content: const Text('أُضيفت الشحنة إلى "شحناتي" ضمن تبويب قيد الانتظار، وتبدأ المتابعة المباشرة عند انطلاق الشاحنة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, 'list'), child: const Text('عرض في شحناتي')),
          FilledButton(onPressed: () => Navigator.pop(c, 'details'), child: const Text('تفاصيل الشحنة')),
        ],
      ),
    );
    if (!mounted) return;
    context.read<ShellController>().openShipments(ShipmentStatus.pending);
    Navigator.popUntil(context, ModalRoute.withName(Routes.home));
    if (action == 'details') Navigator.pushNamed(context, Routes.shipmentDetails, arguments: shipment.id);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => _step--);
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('إنشاء شحنة تصدير')),
          bottomNavigationBar: StepButtons(
            isFirst: _step == 0,
            isLast: _step == _steps.length - 1,
            loading: _loading,
            lastLabel: 'تأكيد وإنشاء الشحنة',
            onBack: () => setState(() => _step--),
            onNext: _next,
          ),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            ResponsiveBody(
              maxWidth: 700,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                StepProgress(steps: _steps, current: _step),
                const SizedBox(height: 20),
                switch (_step) {
                  0 => _exporter(),
                  1 => _importer(),
                  2 => _productStep(),
                  3 => _transport(),
                  _ => _review(),
                },
              ]),
            ),
          ]),
        ),
      );

  Widget _text(TextEditingController c, String label, IconData icon,
          {FormFieldValidator<String>? validator, TextInputType? keyboard, String? hint, bool readOnly = false}) =>
      FieldGap(
        child: TextFormField(
          controller: c,
          readOnly: readOnly,
          keyboardType: keyboard,
          validator: validator ?? (v) => Validators.required(v, label),
          decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon)),
        ),
      );

  Widget _exporter() => Form(
        key: _forms[0],
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const InlineMessage(text: 'تمت تعبئة بيانات المصدّر من ملفك التجاري. يمكنك تعديلها لهذه الشحنة.'),
          const SizedBox(height: 14),
          _text(_expName, 'اسم المسؤول', Icons.person_outline),
          _text(_expCompany, 'اسم المنشأة المصدّرة', Icons.store_outlined),
          _text(_expPhone, 'هاتف التواصل', Icons.phone_outlined, validator: Validators.jordanPhone, keyboard: TextInputType.phone),
          _text(_expCr, 'رقم السجل التجاري', Icons.badge_outlined,
              validator: (v) => Validators.digits(v, min: 4, max: 8, field: 'رقم السجل'), keyboard: TextInputType.number),
        ]),
      );

  Widget _importer() => Form(
        key: _forms[1],
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _text(_impCompany, 'اسم الشركة المستوردة', Icons.business_outlined),
          _text(_impName, 'اسم المسؤول لدى المستورد', Icons.person_outline),
          AppDropdown<String>(
            label: 'محافظة المستورد',
            icon: Icons.location_city_outlined,
            items: MockData.governorates,
            value: _impGovernorate,
            onChanged: (v) => setState(() => _impGovernorate = v),
          ),
          _text(_impPhone, 'هاتف المستورد', Icons.phone_outlined, validator: Validators.jordanPhone, keyboard: TextInputType.phone, hint: '07XXXXXXXX'),
          _text(_impAddress, 'عنوان التسليم', Icons.location_on_outlined),
        ]),
      );

  Widget _productStep() => Form(
        key: _forms[2],
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppDropdown<Product>(
            label: 'المنتج',
            icon: Icons.eco_outlined,
            items: Products.all,
            itemLabel: (p) => '${p.emoji}  ${p.name}',
            value: _product,
            onChanged: (p) => setState(() {
              _product = p;
              if (p != null) _setpoint = p.optimalTempC;
            }),
          ),
          _text(_variety, 'الصنف', Icons.local_florist_outlined, hint: 'مثال: بندورة شيري'),
          _text(_qty, 'الكمية (طن)', Icons.scale_outlined,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => Validators.positiveNumber(v, min: 0.5, max: 30, field: 'الكمية')),
          AppDropdown<String>(
            label: 'نوع التعبئة',
            icon: Icons.inventory_2_outlined,
            items: MockData.packagingTypes,
            value: _packaging,
            onChanged: (v) => setState(() => _packaging = v),
          ),
          AppDropdown<String>(
            label: 'درجة الجودة',
            icon: Icons.grade_outlined,
            items: const ['ممتاز', 'درجة أولى', 'درجة ثانية'],
            value: _grade,
            onChanged: (v) => setState(() => _grade = v ?? _grade),
          ),
          DateField(
            label: 'تاريخ القطاف',
            value: _harvest,
            firstDate: DateTime.now().subtract(const Duration(days: 10)),
            lastDate: DateTime.now().add(const Duration(days: 30)),
            onChanged: (d) => setState(() => _harvest = d),
          ),
          Text('صور المنتج (اختياري)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final img in _productImages)
              InputChip(
                avatar: const Icon(Icons.image_outlined, size: 18),
                label: Text(img),
                onDeleted: () => setState(() => _productImages.remove(img)),
              ),
            ActionChip(
              avatar: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('إضافة صورة'),
              onPressed: () async {
                final name = await pickDocument(context, demoName: 'product_photo_${_productImages.length + 1}.jpg');
                if (name != null) setState(() => _productImages.add(name));
              },
            ),
          ]),
        ]),
      );

  Widget _transport() {
    final t = Theme.of(context).textTheme;
    return Form(
      key: _forms[3],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppDropdown<String>(
          label: 'نوع الشاحنة',
          icon: Icons.local_shipping_outlined,
          items: MockData.truckTypes,
          value: _truckType,
          onChanged: (v) => setState(() => _truckType = v),
        ),
        _text(_plate, 'رقم لوحة الشاحنة', Icons.pin_outlined, validator: Validators.plate, hint: '22-12345'),
        _text(_driver, 'اسم السائق', Icons.badge_outlined),
        _text(_driverPhone, 'هاتف السائق', Icons.phone_outlined, validator: Validators.jordanPhone, keyboard: TextInputType.phone),
        Row(children: [
          Expanded(
            child: AppDropdown<String>(
              label: 'نقطة الانطلاق',
              items: MockData.originHubs,
              value: _origin,
              onChanged: (v) => setState(() => _origin = v),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppDropdown<String>(
              label: 'الوجهة',
              items: MockData.destinations,
              value: _destination,
              onChanged: (v) => setState(() => _destination = v),
              validator: (v) => v == null ? 'اختر الوجهة' : (v == _origin ? 'الوجهة مطابقة للانطلاق' : null),
            ),
          ),
        ]),
        DateField(
          label: 'تاريخ الانطلاق',
          value: _departure,
          onChanged: (d) => setState(() {
            _departure = d;
            if (_arrival != null && !_arrival!.isAfter(d)) _arrival = null;
          }),
        ),
        DateField(
          label: 'تاريخ الوصول المتوقع',
          value: _arrival,
          firstDate: _departure?.add(const Duration(days: 1)),
          onChanged: (d) => setState(() => _arrival = d),
          validator: (v) {
            if (v == null) return 'تاريخ الوصول مطلوب';
            if (_departure != null && !v.isAfter(_departure!)) return 'يجب أن يكون بعد تاريخ الانطلاق';
            return null;
          },
        ),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.ac_unit, color: AppColors.sky),
              const SizedBox(width: 8),
              Expanded(child: Text('نقطة ضبط التبريد', style: t.titleSmall)),
              Text(Fmt.temp(_setpoint), style: t.titleMedium?.copyWith(color: AppColors.primary)),
            ]),
            Slider(
              value: _setpoint,
              min: 0,
              max: 16,
              divisions: 32,
              label: Fmt.temp(_setpoint),
              onChanged: (v) => setState(() => _setpoint = v),
            ),
            if (_product != null) Text('الموصى به لـ${_product!.name}: ${Fmt.temp(_product!.optimalTempC)}', style: t.bodySmall),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('التبريد الذكي'),
              subtitle: const Text('يسمح لطبقة القرار بتعديل نقطة الضبط ضمن حدود آمنة'),
              value: _smartCooling,
              onChanged: (v) => setState(() => _smartCooling = v),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text('مستندات الشحن', style: t.titleSmall),
        const SizedBox(height: 8),
        for (final e in _requiredDocs.entries)
          FilePickTile(
            label: e.value,
            required: true,
            showError: _docsError,
            fileName: _docs[e.key],
            onPick: () async {
              final name = await pickDocument(context, demoName: 'demo_${e.key}.pdf');
              if (name != null) setState(() => _docs[e.key] = name);
            },
            onClear: () => setState(() => _docs.remove(e.key)),
          ),
      ]),
    );
  }

  Widget _review() {
    final t = Theme.of(context).textTheme;
    final p = _product!;
    Widget section(String title, List<Widget> rows, int step) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(title, style: t.titleSmall)),
                TextButton.icon(onPressed: () => setState(() => _step = step), icon: const Icon(Icons.edit, size: 18), label: const Text('تعديل')),
              ]),
              ...rows,
            ]),
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        color: AppColors.ice,
        child: Row(children: [
          ProductThumb(product: p, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${p.name} — ${_variety.text}', style: t.titleMedium),
              Text('${Fmt.tons(double.parse(_qty.text))} • $_origin ← $_destination', style: t.bodySmall),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      section('المصدّر', [InfoRow(label: 'المنشأة', value: _expCompany.text), InfoRow(label: 'المسؤول', value: _expName.text)], 0),
      section('المستورد', [
        InfoRow(label: 'الشركة', value: _impCompany.text),
        InfoRow(label: 'المحافظة', value: _impGovernorate ?? '-'),
        InfoRow(label: 'العنوان', value: _impAddress.text),
      ], 1),
      section('المنتج', [
        InfoRow(label: 'التعبئة', value: _packaging ?? '-'),
        InfoRow(label: 'الدرجة', value: _grade),
        InfoRow(label: 'القطاف', value: _harvest == null ? '-' : Fmt.date(_harvest!)),
        InfoRow(label: 'الصور', value: '${_productImages.length}'),
      ], 2),
      section('النقل', [
        InfoRow(label: 'الشاحنة', value: '$_truckType • ${_plate.text}'),
        InfoRow(label: 'السائق', value: _driver.text),
        InfoRow(label: 'الانطلاق', value: Fmt.date(_departure!)),
        InfoRow(label: 'الوصول', value: Fmt.date(_arrival!)),
        InfoRow(label: 'التبريد', value: '${Fmt.temp(_setpoint)}${_smartCooling ? ' • ذكي' : ''}'),
        InfoRow(label: 'المستندات', value: '${_docs.length} ملفات'),
      ], 3),
      CheckboxListTile(
        value: _confirmed,
        onChanged: (v) => setState(() => _confirmed = v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        title: const Text('أؤكد صحة بيانات الشحنة ومطابقتها للمستندات المرفقة.'),
      ),
    ]);
  }
}
