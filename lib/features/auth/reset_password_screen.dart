import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../shared/repositories/auth_repository.dart';
import 'widgets/auth_scaffold.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthRepository>().resetPassword(_pass.text);
      if (!mounted) return;
      Navigator.popUntil(context, ModalRoute.withName(Routes.login));
      Toast.success(context, 'تم تغيير كلمة المرور. سجّل الدخول بكلمة المرور الجديدة.');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
        title: 'كلمة مرور جديدة',
        subtitle: '8 أحرف على الأقل وتحتوي على أحرف وأرقام',
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PasswordField(controller: _pass, label: 'كلمة المرور الجديدة', validator: Validators.password),
            const SizedBox(height: 14),
            PasswordField(
              controller: _confirm,
              label: 'تأكيد كلمة المرور',
              validator: (v) => v != _pass.text ? 'كلمتا المرور غير متطابقتين' : null,
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              InlineMessage(text: _error!, color: AppColors.danger, icon: Icons.error_outline),
              const SizedBox(height: 12),
            ],
            LoadingButton(label: 'حفظ كلمة المرور', loading: _loading, onPressed: _submit),
          ]),
        ),
      );
}
