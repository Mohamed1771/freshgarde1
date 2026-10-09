import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_widgets.dart';
import '../../shared/models/inspection_result.dart';
import '../../shared/models/product.dart';
import '../../shared/models/shipment.dart';
import '../../shared/repositories/settings_repository.dart';
import '../../shared/repositories/shipment_repository.dart';
import '../../shared/services/ai_inspection_service.dart';
import '../../shared/services/media_picker.dart';
import '../simulation/live_simulation_service.dart';

enum _Phase { idle, analyzing, done, error }

/// Select image / video → preview → analyze → review result → apply to a shipment.
class AiInspectionScreen extends StatefulWidget {
  const AiInspectionScreen({super.key, this.shipmentId});
  final String? shipmentId;

  @override
  State<AiInspectionScreen> createState() => _AiInspectionScreenState();
}

class _AiInspectionScreenState extends State<AiInspectionScreen> {
  String? _shipmentId;
  Product? _productHint;
  InspectionMedia? _media;
  InspectionResult? _result;
  _Phase _phase = _Phase.idle;
  String? _error;
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    _shipmentId = widget.shipmentId;
    _productHint = _shipmentId == null ? Products.tomato : context.read<ShipmentRepository>().byId(_shipmentId!)?.product;
  }

  Future<void> _pick(Future<InspectionMedia?> Function() picker) async {
    try {
      final m = await picker();
      if (m == null) return;
      setState(() {
        _media = m;
        _result = null;
        _phase = _Phase.idle;
        _applied = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) Toast.error(context, 'تعذّر اختيار الملف على هذا الجهاز. جرّب الصورة التجريبية.');
    }
  }

  Future<void> _analyze() async {
    final media = _media;
    if (media == null) return;
    final service = context.read<SettingsRepository>().aiService;
    setState(() {
      _phase = _Phase.analyzing;
      _error = null;
    });
    try {
      final hint = _productHint?.id;
      final r = media.type == MediaType.image
          ? await service.analyzeImage(media, productHint: hint)
          : await service.analyzeVideo(media, productHint: hint);
      if (!mounted) return;
      setState(() {
        _result = r;
        _phase = _Phase.done;
        _applied = false;
      });
    } on InspectionException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _error = e.message;
        });
      }
    }
  }

  void _apply(Shipment s) {
    context.read<ShipmentRepository>().applyInspection(s, _result!);
    context.read<LiveSimulationService>().applyInspection(s, _result!);
    setState(() => _applied = true);
    Toast.success(context, 'تم تطبيق نتيجة الفحص على الشحنة ${s.id}');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final repo = context.watch<ShipmentRepository>();
    final settings = context.watch<SettingsRepository>();
    final service = settings.aiService;
    final candidates = repo.all.where((s) => s.status != ShipmentStatus.archived).toList();
    final shipment = _shipmentId == null ? null : repo.byId(_shipmentId!);

    return Scaffold(
      appBar: AppBar(title: const Text('فحص المنتج بالذكاء الاصطناعي')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ResponsiveBody(
          maxWidth: 760,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            InlineMessage(
              text: service.isSimulated
                  ? 'المحرك الحالي: ${service.engineLabel}. النتائج توضيحية ومحدّدة مسبقًا ولا تمثّل تحليلًا حقيقيًا. يمكن ربط نموذجك من الإعدادات.'
                  : 'المحرك الحالي: ${service.engineLabel}.',
              color: service.isSimulated ? AppColors.warning : AppColors.success,
              icon: service.isSimulated ? Icons.science_outlined : Icons.memory,
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'الشحنة المرتبطة',
              icon: Icons.local_shipping_outlined,
              items: candidates.map((s) => s.id).toList(),
              itemLabel: (id) {
                final s = repo.byId(id)!;
                return '$id — ${s.product.name} (${s.status.label})';
              },
              value: _shipmentId,
              validator: (_) => null,
              onChanged: (id) => setState(() {
                _shipmentId = id;
                _applied = false;
                if (id != null) _productHint = repo.byId(id)?.product ?? _productHint;
              }),
            ),
            AppDropdown<Product>(
              label: 'نوع المنتج المتوقع',
              icon: Icons.eco_outlined,
              items: Products.all,
              itemLabel: (p) => '${p.emoji}  ${p.name}',
              value: _productHint,
              validator: (_) => null,
              onChanged: (p) => setState(() => _productHint = p),
            ),
            Text('1. اختر الوسائط', style: t.titleMedium),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _source(Icons.photo_library_outlined, 'صورة من المعرض', () => _pick(MediaPicker.pickImage)),
              _source(Icons.photo_camera_outlined, 'التقاط صورة', () => _pick(() => MediaPicker.pickImage(camera: true))),
              _source(Icons.video_library_outlined, 'فيديو', () => _pick(MediaPicker.pickVideo)),
              _source(Icons.image_outlined, 'صورة تجريبية', () => _pick(MediaPicker.sampleImage)),
            ]),
            const SizedBox(height: 14),
            _preview(),
            const SizedBox(height: 16),
            Text('2. التحليل', style: t.titleMedium),
            const SizedBox(height: 10),
            LoadingButton(
              label: _media == null ? 'اختر ملفًا أولًا' : (_result == null ? 'بدء التحليل' : 'إعادة التحليل'),
              icon: Icons.auto_awesome,
              loading: _phase == _Phase.analyzing,
              onPressed: _media == null ? null : _analyze,
            ),
            if (_phase == _Phase.analyzing) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              const SizedBox(height: 6),
              Text(_media!.type == MediaType.video ? 'جارٍ استخراج الإطارات وتحليلها...' : 'جارٍ تحليل الصورة...', style: t.bodySmall),
            ],
            if (_phase == _Phase.error) ...[
              const SizedBox(height: 12),
              InlineMessage(text: _error ?? 'حدث خطأ', color: AppColors.danger, icon: Icons.error_outline),
              TextButton.icon(onPressed: _analyze, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text('3. النتيجة', style: t.titleMedium),
              const SizedBox(height: 10),
              _ResultCard(result: _result!),
              const SizedBox(height: 16),
              if (shipment == null)
                const InlineMessage(text: 'اختر شحنة من الأعلى لتطبيق النتيجة عليها.')
              else if (!_applied)
                FilledButton.icon(
                  onPressed: () => _apply(shipment),
                  icon: const Icon(Icons.playlist_add_check),
                  label: Text('تطبيق النتيجة على ${shipment.id}'),
                )
              else ...[
                InlineMessage(
                  text: 'طُبّقت النتيجة على ${shipment.id}. المحاكاة تبدأ الآن من مرحلة "${_result!.maturityStage.label}".',
                  color: AppColors.success,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openShipment(shipment.id),
                      icon: const Icon(Icons.view_in_ar),
                      label: const Text('المتابعة المباشرة للشحنة'),
                    ),
                  ),
                ]),
              ],
            ],
          ]),
        ),
      ]),
    );
  }

  /// Returns to the shipment's live view, reusing it if it is already below in the stack.
  void _openShipment(String id) {
    final nav = Navigator.of(context);
    var found = false;
    nav.popUntil((r) {
      if (r.settings.name == Routes.shipmentDetails && r.settings.arguments == id) return found = true;
      return r.isFirst || r.settings.name == Routes.home;
    });
    if (!found) nav.pushNamed(Routes.shipmentDetails, arguments: id);
  }

  Widget _source(IconData i, String label, VoidCallback onTap) =>
      ActionChip(avatar: Icon(i, size: 18, color: AppColors.primary), label: Text(label), onPressed: _phase == _Phase.analyzing ? null : onTap);

  Widget _preview() {
    final t = Theme.of(context).textTheme;
    final m = _media;
    if (m == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.ice,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.sky.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.add_photo_alternate_outlined, size: 44, color: AppColors.primary),
          const SizedBox(height: 8),
          Text('لم يتم اختيار ملف', style: t.bodyMedium),
          Text('صورة JPG/PNG أو فيديو قصير حتى 30 ثانية', style: t.bodySmall),
        ]),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (m.type == MediaType.image)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Image.memory(m.bytes, fit: BoxFit.cover, errorBuilder: (_, _, _) => _videoLike(Icons.broken_image_outlined, 'تعذّر عرض الصورة')),
          )
        else
          _videoLike(Icons.play_circle_outline, 'فيديو جاهز للتحليل'),
        ListTile(
          leading: Icon(m.type == MediaType.image ? Icons.image_outlined : Icons.movie_outlined, color: AppColors.primary),
          title: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${m.type == MediaType.image ? 'صورة' : 'فيديو'} • ${m.sizeLabel}'),
          trailing: IconButton(
            tooltip: 'إزالة',
            icon: const Icon(Icons.close),
            onPressed: _phase == _Phase.analyzing
                ? null
                : () => setState(() {
                      _media = null;
                      _result = null;
                      _phase = _Phase.idle;
                    }),
          ),
        ),
      ]),
    );
  }

  Widget _videoLike(IconData icon, String label) => Container(
        height: 180,
        color: AppColors.navy,
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: AppColors.white),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.white)),
        ]),
      );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final InspectionResult result;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = result;
    final product = Products.match(r.detectedProduct);
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('نتيجة الفحص', style: t.titleMedium)),
          r.isSimulated ? const MockBadge(label: 'نتيجة محاكاة — ليست AI حقيقي') : const StatusChip(label: 'نموذج AI', color: AppColors.success, dense: true),
        ]),
        const SizedBox(height: 12),
        TileGrid(minTileWidth: 150, children: [
          MetricTile(icon: Icons.eco_outlined, label: 'المنتج المكتشف', value: product != null ? '${product.emoji} ${product.name}' : r.detectedProduct),
          MetricTile(icon: Icons.verified_outlined, label: 'الثقة', value: Fmt.pct(r.confidence * 100), color: r.confidence >= 0.85 ? AppColors.success : AppColors.warning),
          MetricTile(icon: Icons.star_outline, label: 'درجة الجودة', value: Fmt.pct(r.qualityScore)),
          MetricTile(icon: Icons.bug_report_outlined, label: 'العيوب المرئية', value: '${r.defects.length}', color: r.defects.isEmpty ? AppColors.success : AppColors.warning),
        ]),
        const SizedBox(height: 16),
        Text('مرحلة النضج: ${r.maturityStage.label}', style: t.titleSmall?.copyWith(color: r.maturityStage.color)),
        const SizedBox(height: 8),
        Row(children: [
          for (final s in MaturityStage.values)
            Expanded(
              child: Container(
                height: s == r.maturityStage ? 16 : 10,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: s == r.maturityStage ? 1 : 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(MaturityStage.values.first.label, style: t.bodySmall),
          Text(MaturityStage.values.last.label, style: t.bodySmall),
        ]),
        const SizedBox(height: 16),
        Text('العيوب المرئية', style: t.titleSmall),
        const SizedBox(height: 6),
        if (r.defects.isEmpty)
          Text('لم تُرصد عيوب ظاهرة.', style: t.bodyMedium)
        else
          for (final d in r.defects)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                SizedBox(width: 120, child: Text(d.label, style: t.bodyMedium)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: d.severity,
                      minHeight: 8,
                      backgroundColor: AppColors.ice,
                      color: d.severity > 0.5 ? AppColors.danger : AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${d.areaPct.toStringAsFixed(1)}% من السطح', style: t.bodySmall),
              ]),
            ),
        const SizedBox(height: 12),
        InlineMessage(text: r.recommendation, icon: Icons.lightbulb_outline),
        const SizedBox(height: 8),
        Text('الإصدار: ${r.modelVersion} • ${r.mediaType == MediaType.video ? 'فيديو' : 'صورة'}', style: t.bodySmall),
      ]),
    );
  }
}
