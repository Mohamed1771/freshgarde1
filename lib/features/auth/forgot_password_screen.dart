import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../shared/repositories/auth_repository.dart';
import 'widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthRepository>().requestPasswordReset(_id.text);
      if (!mounted) return;
      Navigator.pushNamed(context, Routes.otp);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'استعادة كلمة المرور',
        subtitle: 'أدخل بريدك أو رقم هاتفك المسجّل وسنرسل لك رمز تحقق',
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(
              controller: _id,
              validator: Validators.emailOrPhone,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني أو رقم الهاتف', prefixIcon: Icon(Icons.alternate_email)),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              InlineMessage(text: _error!, color: AppColors.danger, icon: Icons.error_outline),
              const SizedBox(height: 12),
            ],
            LoadingButton(label: 'إرسال رمز التحقق', loading: _loading, onPressed: _submit),
          ]),
        ),
      );
}
