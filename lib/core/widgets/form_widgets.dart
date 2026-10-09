import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Horizontal numbered step indicator used by the multi-step forms.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.steps, required this.current});
  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('الخطوة ${current + 1} من ${steps.length}', style: t.bodySmall),
          const Spacer(),
          Text(steps[current], style: t.titleSmall?.copyWith(color: AppColors.primary)),
        ]),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= current ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (i < steps.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}

/// Labeled spacing wrapper for form fields.
class FieldGap extends StatelessWidget {
  const FieldGap({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14), child: child);
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.itemLabel,
    this.validator,
    this.icon,
  });

  final String label;
  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String Function(T)? itemLabel;
  final FormFieldValidator<T>? validator;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => FieldGap(
        child: DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label, prefixIcon: icon == null ? null : Icon(icon)),
          items: [
            for (final i in items)
              DropdownMenuItem(value: i, child: Text(itemLabel?.call(i) ?? i.toString(), overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
          validator: validator ?? (v) => v == null ? 'اختر $label' : null,
        ),
      );
}

/// Read-only field that opens a date picker.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.label, required this.value, required this.onChanged, this.firstDate, this.lastDate, this.validator});
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? Function(DateTime?)? validator;

  @override
  Widget build(BuildContext context) => FieldGap(
        child: FormField<DateTime>(
          key: ValueKey(value),
          initialValue: value,
          validator: validator ?? (v) => v == null ? '$label مطلوب' : null,
          builder: (state) => InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final now = DateTime.now();
              final first = firstDate ?? DateTime(now.year, now.month, now.day);
              final d = await showDatePicker(
                context: context,
                initialDate: value != null && !value!.isBefore(first) ? value! : first,
                firstDate: first,
                lastDate: lastDate ?? now.add(const Duration(days: 365)),
              );
              if (d != null) {
                onChanged(d);
                state.didChange(d);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: const Icon(Icons.calendar_month_outlined),
                errorText: state.errorText,
              ),
              child: Text(value == null ? 'اختر التاريخ' : Fmt.date(value!),
                  style: TextStyle(color: value == null ? AppColors.textMuted : AppColors.textPrimary)),
            ),
          ),
        ),
      );
}

/// Document / image selection placeholder. Only the file name is stored.
class FilePickTile extends StatelessWidget {
  const FilePickTile({
    super.key,
    required this.label,
    required this.fileName,
    required this.onPick,
    required this.onClear,
    this.required = false,
    this.hint,
    this.showError = false,
  });

  final String label;
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool required;
  final String? hint;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final picked = fileName != null;
    final err = showError && required && !picked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: picked ? AppColors.ice : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: err ? AppColors.danger : (picked ? AppColors.sky : AppColors.border)),
        ),
        child: ListTile(
          onTap: onPick,
          leading: Icon(picked ? Icons.description : Icons.upload_file, color: picked ? AppColors.primary : AppColors.textSecondary),
          title: Text('$label${required ? ' *' : ''}', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(
            picked ? fileName! : (err ? 'هذا المستند مطلوب' : (hint ?? 'اضغط لاختيار ملف (صورة أو PDF)')),
            style: t.bodySmall?.copyWith(color: err ? AppColors.danger : null),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: picked
              ? IconButton(tooltip: 'إزالة', icon: const Icon(Icons.close), onPressed: onClear)
              : const Icon(Icons.add_circle_outline, color: AppColors.primary),
        ),
      ),
    );
  }
}

/// Bottom-of-form navigation for multi-step wizards.
class StepButtons extends StatelessWidget {
  const StepButtons({super.key, required this.isFirst, required this.isLast, required this.onBack, required this.onNext, this.loading = false, this.lastLabel = 'تأكيد وإرسال'});
  final bool isFirst;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool loading;
  final String lastLabel;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            if (!isFirst) ...[
              Expanded(child: OutlinedButton(onPressed: loading ? null : onBack, child: const Text('السابق'))),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: loading ? null : onNext,
                child: loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white))
                    : Text(isLast ? lastLabel : 'التالي'),
              ),
            ),
          ]),
        ),
      );
}
