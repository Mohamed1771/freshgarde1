import 'package:flutter/foundation.dart';

import '../models/trader.dart';
import 'mock_data.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// In-memory authentication. Accounts and passwords live only for the current session.
/// Replace with a real API client without changing the screens (same public methods).
class AuthRepository extends ChangeNotifier {
  AuthRepository() {
    final demo = MockData.demoTrader();
    _accounts.add(_Account(demo, MockData.demoPassword));
  }

  final _accounts = <_Account>[];
  Trader? _current;
  String? _resetFor;
  bool _otpVerified = false;

  Trader? get currentTrader => _current;
  bool get isLoggedIn => _current != null;

  static const _latency = Duration(milliseconds: 700);

  _Account? _find(String identifier) {
    final id = _normalize(identifier);
    for (final a in _accounts) {
      if (a.trader.email.toLowerCase() == id || _normalize(a.trader.phone) == id) return a;
    }
    return null;
  }

  static String _normalize(String s) {
    var v = s.trim().toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
    if (v.startsWith('+962')) v = '0${v.substring(4)}';
    if (v.startsWith('00962')) v = '0${v.substring(5)}';
    return v;
  }

  Future<Trader> login(String identifier, String password) async {
    await Future<void>.delayed(_latency);
    final acc = _find(identifier);
    if (acc == null || acc.password != password) {
      throw AuthException('بيانات الدخول غير صحيحة. جرّب الحساب التجريبي الموضّح أسفل الشاشة.');
    }
    _current = acc.trader;
    notifyListeners();
    return acc.trader;
  }

  Future<Trader> register(Trader trader, String password) async {
    await Future<void>.delayed(_latency);
    if (_find(trader.email) != null || _find(trader.phone) != null) {
      throw AuthException('يوجد حساب مسجّل بهذا البريد أو رقم الهاتف.');
    }
    _accounts.add(_Account(trader, password));
    _current = trader;
    notifyListeners();
    return trader;
  }

  /// Demo only: simulates the back-office approving the documents.
  Future<void> approveCurrentDemo() async {
    await Future<void>.delayed(_latency);
    _current?.status = VerificationStatus.verified;
    notifyListeners();
  }

  void logout() {
    _current = null;
    notifyListeners();
  }

  Future<void> requestPasswordReset(String identifier) async {
    await Future<void>.delayed(_latency);
    if (_find(identifier) == null) throw AuthException('لا يوجد حساب مرتبط بهذه البيانات.');
    _resetFor = identifier;
    _otpVerified = false;
  }

  Future<void> verifyOtp(String code) async {
    await Future<void>.delayed(_latency);
    if (code != MockData.demoOtp) throw AuthException('رمز التحقق غير صحيح. الرمز التجريبي هو ${MockData.demoOtp}.');
    _otpVerified = true;
  }

  Future<void> resetPassword(String newPassword) async {
    await Future<void>.delayed(_latency);
    final acc = _resetFor == null ? null : _find(_resetFor!);
    if (acc == null || !_otpVerified) throw AuthException('انتهت صلاحية جلسة الاستعادة. أعد المحاولة.');
    acc.password = newPassword;
    _resetFor = null;
    _otpVerified = false;
  }
}

class _Account {
  _Account(this.trader, this.password);
  final Trader trader;
  String password;
}
