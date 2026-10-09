import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/inspection_result.dart';
import 'ai_inspection_service.dart';

/// Integration with the Python (FastAPI) inspection model.
///
/// Expected endpoints:
/// * `POST {baseUrl}/predict/image` — multipart field `file` (+ optional `product_hint`)
/// * `POST {baseUrl}/predict/video` — multipart field `file` (+ optional `product_hint`)
///
/// Both must return the JSON documented on [InspectionResult] with `"simulated": false`.
/// For Android emulators use `http://10.0.2.2:8000`; for Chrome, enable CORS on the FastAPI app.
class FastApiInspectionService implements AiInspectionService {
  FastApiInspectionService({required this.baseUrl, http.Client? client, this.timeout = const Duration(seconds: 60)})
      : _client = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  @override
  String get engineLabel => 'نموذج FastAPI ($baseUrl)';

  @override
  bool get isSimulated => false;

  @override
  Future<InspectionResult> analyzeImage(InspectionMedia media, {String? productHint}) =>
      _post('/predict/image', media, productHint);

  @override
  Future<InspectionResult> analyzeVideo(InspectionMedia media, {String? productHint}) =>
      _post('/predict/video', media, productHint);

  Future<InspectionResult> _post(String path, InspectionMedia media, String? hint) async {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$path');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('file', media.bytes, filename: media.name));
    if (hint != null) req.fields['product_hint'] = hint;

    try {
      final streamed = await _client.send(req).timeout(timeout);
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode != 200) {
        throw InspectionException('رفض الخادم الطلب (${res.statusCode}).');
      }
      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return InspectionResult.fromJson(json, mediaType: media.type, fileName: media.name);
    } on InspectionException {
      rethrow;
    } on FormatException {
      throw InspectionException('استجابة الخادم ليست بصيغة JSON المتوقعة.');
    } catch (e) {
      throw InspectionException('تعذّر الاتصال بخدمة الفحص على $baseUrl. تأكد من تشغيل الخادم.');
    }
  }
}
