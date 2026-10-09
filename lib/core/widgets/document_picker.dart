import 'package:flutter/material.dart';

import '../../shared/services/media_picker.dart';
import 'common.dart';

/// Asks the user where a document comes from and returns the selected file name.
/// Only the file name is returned and stored; contents are never retained in this demo.
Future<String?> pickDocument(BuildContext context, {required String demoName}) async {
  final choice = await showModalBottomSheet<int>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('اختيار من الجهاز'), onTap: () => Navigator.pop(c, 0)),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('استخدام ملف تجريبي'),
          subtitle: const Text('للعرض فقط — لا يتم رفع أي ملف'),
          onTap: () => Navigator.pop(c, 1),
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
  if (choice == null) return null;
  if (choice == 1) return demoName;
  try {
    return await MediaPicker.pickDocumentName();
  } catch (_) {
    if (context.mounted) Toast.error(context, 'تعذّر فتح معرض الملفات على هذا الجهاز. استخدم الملف التجريبي.');
    return null;
  }
}
