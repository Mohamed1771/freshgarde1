import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/inspection_result.dart';
import 'ai_inspection_service.dart';

/// Thin wrapper around image_picker so screens stay platform-agnostic (Android, iOS, Web).
class MediaPicker {
  MediaPicker._();
  static final _picker = ImagePicker();

  static const sampleImageAsset = 'assets/images/sample_tomatoes.png';

  static Future<InspectionMedia?> pickImage({bool camera = false}) async {
    final f = await _picker.pickImage(source: camera ? ImageSource.camera : ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (f == null) return null;
    return InspectionMedia(name: f.name, bytes: await f.readAsBytes(), type: MediaType.image, mimeType: f.mimeType);
  }

  static Future<InspectionMedia?> pickVideo({bool camera = false}) async {
    final f = await _picker.pickVideo(source: camera ? ImageSource.camera : ImageSource.gallery, maxDuration: const Duration(seconds: 30));
    if (f == null) return null;
    return InspectionMedia(name: f.name, bytes: await f.readAsBytes(), type: MediaType.video, mimeType: f.mimeType);
  }

  /// Bundled sample so the demo works on emulators without a gallery.
  static Future<InspectionMedia> sampleImage() async {
    final data = await rootBundle.load(sampleImageAsset);
    return InspectionMedia(name: 'sample_tomatoes.png', bytes: data.buffer.asUint8List(), type: MediaType.image, mimeType: 'image/png');
  }

  /// Returns only the picked file name: document contents are never kept in the demo.
  static Future<String?> pickDocumentName() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    return f?.name;
  }
}
