import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../shared/repositories/auth_repository.dart';
import '../../shared/repositories/mock_data.dart';
import 'widgets/auth_scaffold.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  Timer? _timer;
  int _seconds = 60;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) t.cancel();
      if (mounted) setState(() => _seconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) {
      setState(() => _error = 'أدخل الرمز المكوّن من 6 أرقام');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthRepository>().verifyOtp(_code.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.resetPassword);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AuthScaffold(
      title: 'رمز التحقق',
      subtitle: 'أدخل الرمز المكوّن من 6 أرقام المرسل إليك',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: t.headlineMedium?.copyWith(letterSpacing: 18),
            decoration: InputDecoration(counterText: '', hintText: '------', errorText: _error),
            onChanged: (v) {
              if (v.length == 6) _verify();
            },
          ),
        ),
        const SizedBox(height: 16),
        LoadingButton(label: 'تحقق', loading: _loading, onPressed: _verify),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _seconds > 0
              ? null
              : () {
                  _startTimer();
                  Toast.info(context, 'تم إرسال رمز جديد (تجريبي)');
                },
          child: Text(_seconds > 0 ? 'إعادة الإرسال بعد $_seconds ثانية' : 'إعادة إرسال الرمز'),
        ),
        const SizedBox(height: 8),
        InlineMessage(text: 'وضع تجريبي: لا تُرسل رسائل فعلية. الرمز هو ${MockData.demoOtp}', color: AppColors.warning, icon: Icons.science_outlined),
      ]),
    );
  }
}
