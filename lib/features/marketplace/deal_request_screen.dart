import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_widgets.dart';
import '../../core/widgets/product_visual.dart';
import '../../shared/models/trading_offer.dart';
import '../../shared/repositories/deal_repository.dart';
import '../../shared/repositories/mock_data.dart';
import '../../shared/repositories/offer_repository.dart';

class DealRequestScreen extends StatefulWidget {
  const DealRequestScreen({super.key, required this.offerId});
  final String offerId;

  @override
  State<DealRequestScreen> createState() => _DealRequestScreenState();
}

class _DealRequestScreenState extends State<DealRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _date;
  String? _city;
  String? _terms;
  bool _reefer = true;
  bool _loading = false;

  @override
  void dispose() {
    _qty.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit(TradingOffer offer) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final repo = context.read<DealRepository>();
    await repo.submit(DealRequest(
      id: repo.nextId(),
      offer: offer,
      quantityTons: double.parse(_qty.text),
      deliveryDate: _date!,
      deliveryCity: _city!,
      paymentTerms: _terms!,
      needsRefrigeratedTransport: _reefer,
      notes: _notes.text.trim(),
      counterparty: offer.sellerName,
      incoming: false,
    ));
    if (!mounted) return;
    setState(() => _loading = false);
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
        title: const Text('تم إرسال الطلب'),
        content: Text('أُرسل طلبك إلى ${offer.sellerName}. ستصلك إشعارات عند الرد. (طلب تجريبي)'),
        actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('عرض صفقاتي'))],
      ),
    );
    if (!mounted) return;
    context.read<ShellController>().go(MainTab.deals);
    Navigator.popUntil(context, ModalRoute.withName(Routes.home));
  }

  @override
  Widget build(BuildContext context) {
    final offer = context.watch<OfferRepository>().byId(widget.offerId);
    if (offer == null) return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.search_off, title: 'العرض غير موجود'));
    final t = Theme.of(context).textTheme;
    final qty = double.tryParse(_qty.text) ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('طلب صفقة')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: LoadingButton(label: 'إرسال الطلب', icon: Icons.send, loading: _loading, onPressed: () => _submit(offer)),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          ResponsiveBody(
            maxWidth: 640,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AppCard(
                child: Row(children: [
                  ProductThumb(product: offer.product, size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(offer.title, style: t.titleSmall),
                      Text('${offer.sellerName} • ${Fmt.money(offer.pricePerTonJod)} / طن', style: t.bodySmall),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              FieldGap(
                child: TextFormField(
                  controller: _qty,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => Validators.positiveNumber(v, min: offer.minOrderTons, max: offer.quantityTons, field: 'الكمية'),
                  decoration: InputDecoration(
                    labelText: 'الكمية المطلوبة (طن)',
                    helperText: 'بين ${Fmt.tons(offer.minOrderTons)} و${Fmt.tons(offer.quantityTons)}',
                    prefixIcon: const Icon(Icons.scale_outlined),
                  ),
                ),
              ),
              DateField(
                label: 'تاريخ التسليم المطلوب',
                value: _date,
                firstDate: offer.availableFrom.isAfter(DateTime.now()) ? offer.availableFrom : null,
                onChanged: (d) => setState(() => _date = d),
              ),
              AppDropdown<String>(
                label: 'مدينة التسليم',
                icon: Icons.location_on_outlined,
                items: MockData.destinations,
                value: _city,
                onChanged: (v) => setState(() => _city = v),
              ),
              AppDropdown<String>(
                label: 'شروط الدفع',
                icon: Icons.payments_outlined,
                items: MockData.paymentTerms,
                value: _terms,
                onChanged: (v) => setState(() => _terms = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('أحتاج نقلًا مبرّدًا عبر FreshRoute'),
                subtitle: const Text('شاحنة مبرّدة مع مراقبة ذكية للحرارة'),
                value: _reefer,
                onChanged: (v) => setState(() => _reefer = v),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                maxLength: 300,
                decoration: const InputDecoration(labelText: 'ملاحظات للبائع (اختياري)', alignLabelWithHint: true),
              ),
              const SizedBox(height: 8),
              AppCard(
                color: AppColors.ice,
                child: Row(children: [
                  Text('القيمة التقديرية', style: t.titleSmall),
                  const Spacer(),
                  Text(Fmt.money(qty * offer.pricePerTonJod), style: t.titleLarge?.copyWith(color: AppColors.primary)),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
