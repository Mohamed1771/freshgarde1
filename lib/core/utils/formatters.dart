/// Small, dependency-free formatters (Arabic UI, Latin digits for readability of IDs and numbers).
abstract final class Fmt {
  static String date(DateTime d) => '${d.year}/${_pad(d.month)}/${_pad(d.day)}';
  static String dateTime(DateTime d) => '${date(d)}  ${_pad(d.hour)}:${_pad(d.minute)}';
  static String time(DateTime d) => '${_pad(d.hour)}:${_pad(d.minute)}';
  static String money(double v) => '${_thousands(v.round())} د.أ';
  static String tons(double v) => '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)} طن';
  // Leading LRM keeps "12.5°C" in visual order inside RTL text.
  static String temp(double v) => '‎${v.toStringAsFixed(1)}°C';
  static String pct(double v, [int digits = 0]) => '${v.toStringAsFixed(digits)}%';
  static String hours(double h) => '${h.toStringAsFixed(1)} س';

  static String ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} ساعة';
    return 'قبل ${diff.inDays} يوم';
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');
  static String _thousands(int v) {
    final s = v.abs().toString();
    final b = StringBuffer(v < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}

/// Client-side validators shared by all forms.
abstract final class Validators {
  static String? required(String? v, [String field = 'هذا الحقل']) =>
      (v == null || v.trim().isEmpty) ? '$field مطلوب' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
    return RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(v.trim()) ? null : 'صيغة البريد الإلكتروني غير صحيحة';
  }

  /// Jordanian mobile: 07[789]XXXXXXX or +9627[789]XXXXXXX.
  static String? jordanPhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'رقم الهاتف مطلوب';
    final s = v.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^(\+9627|009627|07)[789]\d{7}$').hasMatch(s) ? null : 'أدخل رقم هاتف أردني صحيح (07XXXXXXXX)';
  }

  /// Generic international phone for foreign importers.
  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'رقم الهاتف مطلوب';
    return RegExp(r'^\+?\d{8,15}$').hasMatch(v.replaceAll(RegExp(r'[\s-]'), '')) ? null : 'رقم هاتف غير صحيح';
  }

  static String? emailOrPhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني أو رقم الهاتف';
    return v.contains('@') ? email(v) : jordanPhone(v);
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
    if (v.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) return 'يجب أن تحتوي على أحرف وأرقام';
    return null;
  }

  static String? digits(String? v, {required int min, int? max, String field = 'الرقم'}) {
    if (v == null || v.trim().isEmpty) return '$field مطلوب';
    final s = v.trim();
    if (!RegExp(r'^\d+$').hasMatch(s)) return '$field يجب أن يحتوي على أرقام فقط';
    if (s.length < min || s.length > (max ?? min)) {
      return max == null || max == min ? '$field يجب أن يكون $min أرقام' : '$field بين $min و$max أرقام';
    }
    return null;
  }

  static String? positiveNumber(String? v, {double? min, double? max, String field = 'القيمة'}) {
    final n = double.tryParse(v?.trim() ?? '');
    if (n == null || n <= 0) return 'أدخل $field صحيحة';
    if (min != null && n < min) return 'الحد الأدنى ${min % 1 == 0 ? min.toInt() : min}';
    if (max != null && n > max) return 'الحد الأعلى ${max % 1 == 0 ? max.toInt() : max}';
    return null;
  }

  /// Jordanian plate format, e.g. 22-12345.
  static String? plate(String? v) {
    if (v == null || v.trim().isEmpty) return 'رقم اللوحة مطلوب';
    return RegExp(r'^\d{1,2}-\d{3,6}$').hasMatch(v.trim()) ? null : 'الصيغة: 22-12345';
  }
}
