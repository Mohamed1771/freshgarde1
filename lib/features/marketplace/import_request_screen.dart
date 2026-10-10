import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_widgets.dart';
import '../../shared/models/inspection_result.dart';
import '../../shared/models/sensor_reading.dart';
import '../../shared/models/shipment.dart';
import '../../shared/models/trading_offer.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../shared/repositories/mock_data.dart';
import '../../shared/repositories/offer_repository.dart';
import '../../shared/repositories/shipment_repository.dart';

/// Import request: the importer completes what the offer leaves open (delivery city, receiving party,
/// address, arrival date). Submitting turns the offer into a pending shipment and removes it from the market.
class ImportRequestScreen extends StatefulWidget {
  const ImportRequestScreen({super.key, required this.offerId});
  final String offerId;

  @override
  State<ImportRequestScreen> createState() => _ImportRequestScreenState();
}

class _ImportRequestScreenState extends State<ImportRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String? _city;
  String? _country;
  DateTime? _arrival;
  bool _confirmed = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Prefill the receiving party from the signed-in trader; it can be changed.
    final t = context.read<AuthRepository>().currentTrader;
    _company.text = t?.companyName ?? '';
    _contact.text = t?.fullName ?? '';
    _phone.text = t?.phone ?? '';
  }

  @override
  void dispose() {
    for (final c in [_company, _contact, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(TradingOffer o) async {
    if (!_form.currentState!.validate()) return;
    if (!_confirmed) {
      Toast.error(context, 'يرجى تأكيد بيانات الطلب');
      return;
    }
    setState(() => _loading = true);
    final shipments = context.read<ShipmentRepository>();
    final offers = context.read<OfferRepository>();
    final p = o.product;
    final shipment = Shipment(
      id: shipments.nextId(),
      exporterName: o.partnerContact,
      exporterCompany: o.partner,
      importerName: _contact.text.trim(),
      importerCompany: _company.text.trim(),
      importerCountry: _country!,
      product: p,
      variety: o.variety,
      quantityTons: o.quantityTons,
      packaging: o.packaging,
      origin: o.origin,
      destination: _city!,
      departure: o.departure,
      eta: _arrival!,
      status: ShipmentStatus.pending,
      truckType: o.truckType,
      truckPlate: o.truckPlate,
      driverName: o.driverName,
      coolingSetpointC: o.coolingSetpointC,
      smartCooling: o.smartCooling,
      reading: SensorReading(time: DateTime.now(), temperatureC: o.coolingSetpointC, humidityPct: p.optimalHumidity, setpointC: o.coolingSetpointC),
      qualityPct: 95,
      forecast: const QualityForecast(arrivalQualityPct: 90, shelfLifeDays: 8, arrivalStage: MaturityStage.turning, basis: 'تقدير أولي'),
    );
    await shipments.create(shipment);
    offers.remove(o.id);
    if (!mounted) return;
    setState(() => _loading = false);

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 52),
        title: Text('تم طلب الاستيراد — الشحنة ${shipment.id}'),
        content: Text('أُنشئت الشحنة إلى $_city وأُزيل العرض من السوق. تجدها في "شحناتي" ضمن قيد الانتظار.'),
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
  Widget build(BuildContext context) {
    final o = context.watch<OfferRepository>().byId(widget.offerId);
    if (o == null) {
      return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.inventory_2_outlined, title: 'هذا العرض لم يعد متاحًا'));
    }
    final t = Theme.of(context).textTheme;
    final first = o.departure.add(const Duration(days: 1));

    Widget text(TextEditingController c, String label, IconData icon, {FormFieldValidator<String>? validator, TextInputType? keyboard}) =>
        FieldGap(
          child: TextFormField(
            controller: c,
            keyboardType: keyboard,
            validator: validator ?? (v) => Validators.required(v, label),
            decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('طلب استيراد')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: LoadingButton(label: 'إرسال الطلب وإنشاء الشحنة', icon: Icons.send, loading: _loading, onPressed: () => _submit(o)),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          ResponsiveBody(
            maxWidth: 640,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AppCard(
                color: AppColors.ice,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.title, style: t.titleMedium),
                  const SizedBox(height: 4),
                  Text('${Fmt.tons(o.quantityTons)} • ${Fmt.money(o.pricePerTonJod)} / طن • من ${o.origin}', style: t.bodySmall),
                  Text('الانطلاق ${Fmt.date(o.departure)} • ${o.partner}', style: t.bodySmall),
                ]),
              ),
              const SectionHeader('مكان التسليم'),
              AppDropdown<String>(
                label: 'مدينة التسليم',
                icon: Icons.flag_outlined,
                items: o.allowedDestinations,
                value: _city,
                onChanged: (v) => setState(() => _city = v),
              ),
              text(_address, 'عنوان التسليم', Icons.location_on_outlined),
              DateField(
                label: 'تاريخ الوصول المطلوب',
                value: _arrival,
                firstDate: first.isAfter(DateTime.now()) ? first : null,
                onChanged: (d) => setState(() => _arrival = d),
              ),
              const SectionHeader('الجهة المستلمة'),
              text(_company, 'اسم الشركة المستلمة', Icons.business_outlined),
              text(_contact, 'اسم المسؤول عن الاستلام', Icons.person_outline),
              AppDropdown<String>(
                label: 'دولة الجهة المستلمة',
                icon: Icons.public,
                items: MockData.countries,
                value: _country,
                onChanged: (v) => setState(() => _country = v),
              ),
              text(_phone, 'هاتف التواصل', Icons.phone_outlined, validator: Validators.phone, keyboard: TextInputType.phone),
              CheckboxListTile(
                value: _confirmed,
                onChanged: (v) => setState(() => _confirmed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text('أؤكد طلب هذه الشحنة وصحة بيانات التسليم.'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
