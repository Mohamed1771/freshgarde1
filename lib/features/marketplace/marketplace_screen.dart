import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_widgets.dart';
import '../../shared/models/product.dart';
import '../../shared/repositories/mock_data.dart';
import '../../shared/repositories/offer_repository.dart';
import 'widgets/offer_card.dart';

/// Import marketplace: search, category chips, advanced filters and sorting.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _search = TextEditingController();
  OfferFilter _filter = const OfferFilter();
  int _syncedVersion = -1;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _syncFromShell(ShellController shell) {
    if (shell.marketplaceQueryVersion == _syncedVersion) return;
    _syncedVersion = shell.marketplaceQueryVersion;
    _search.text = shell.marketplaceQuery;
    _filter = _filter.copyWith(query: shell.marketplaceQuery);
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<OfferFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(initial: _filter),
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    _syncFromShell(context.watch<ShellController>());
    final t = Theme.of(context).textTheme;
    final offers = context.watch<OfferRepository>().search(_filter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ResponsiveBody(
          maxWidth: 1200,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _filter = _filter.copyWith(query: v)),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج، بائع أو مدينة',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'مسح',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _search.clear();
                              _filter = _filter.copyWith(query: '');
                            }),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'الفلاتر',
                onPressed: _openFilters,
                icon: Badge(isLabelVisible: _filter.activeCount > 0, label: Text('${_filter.activeCount}'), child: const Icon(Icons.tune)),
              ),
            ]),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('الكل', _filter.category == null, () => _filter.copyWith(category: () => null)),
                for (final c in ProductCategory.values) _chip(c.label, _filter.category == c, () => _filter.copyWith(category: () => c)),
                _chip('متوفر الآن', _filter.availableNowOnly, () => _filter.copyWith(availableNowOnly: !_filter.availableNowOnly)),
                _chip('بائع موثّق', _filter.verifiedOnly, () => _filter.copyWith(verifiedOnly: !_filter.verifiedOnly)),
              ]),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Text('${offers.length} عرض', style: t.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              PopupMenuButton<OfferSort>(
                initialValue: _filter.sort,
                onSelected: (s) => setState(() => _filter = _filter.copyWith(sort: s)),
                itemBuilder: (_) => [for (final s in OfferSort.values) PopupMenuItem(value: s, child: Text(s.label))],
                child: Row(children: [
                  const Icon(Icons.sort, size: 20, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(_filter.sort.label, style: t.bodyMedium?.copyWith(color: AppColors.primary)),
                ]),
              ),
            ]),
            const SizedBox(height: 8),
            offers.isEmpty
                ? EmptyState(
                    icon: Icons.search_off,
                    title: 'لا توجد عروض مطابقة',
                    message: 'جرّب تعديل كلمات البحث أو إزالة بعض الفلاتر.',
                    actionLabel: 'إعادة ضبط الفلاتر',
                    onAction: () => setState(() {
                      _search.clear();
                      _filter = const OfferFilter();
                    }),
                  )
                : OfferList(offers: offers),
          ]),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, OfferFilter Function() next) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: FilterChip(label: Text(label), selected: selected, onSelected: (_) => setState(() => _filter = next())),
      );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final OfferFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late OfferFilter _f = widget.initial;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text('فلترة العروض', style: t.titleLarge),
          const SizedBox(height: 16),
          AppDropdown<String?>(
            label: 'منطقة المنشأ',
            icon: Icons.agriculture_outlined,
            items: [null, ...MockData.originHubs],
            itemLabel: (v) => v ?? 'الكل',
            value: _f.origin,
            validator: (_) => null,
            onChanged: (v) => setState(() => _f = _f.copyWith(origin: () => v)),
          ),
          AppDropdown<String?>(
            label: 'الوجهة',
            icon: Icons.flag_outlined,
            items: [null, ...MockData.destinations],
            itemLabel: (v) => v ?? 'الكل',
            value: _f.destination,
            validator: (_) => null,
            onChanged: (v) => setState(() => _f = _f.copyWith(destination: () => v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('المتوفر الآن فقط'),
            value: _f.availableNowOnly,
            onChanged: (v) => setState(() => _f = _f.copyWith(availableNowOnly: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('البائعون الموثّقون فقط'),
            value: _f.verifiedOnly,
            onChanged: (v) => setState(() => _f = _f.copyWith(verifiedOnly: v)),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, OfferFilter(query: _f.query)),
                child: const Text('مسح الكل'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: FilledButton(onPressed: () => Navigator.pop(context, _f), child: const Text('تطبيق'))),
          ]),
        ]),
      ),
    );
  }
}
