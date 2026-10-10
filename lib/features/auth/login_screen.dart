import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../shared/models/trader.dart';
import '../../shared/repositories/auth_repository.dart';
import 'widgets/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final trader = await context.read<AuthRepository>().login(_id.text, _pass.text);
      if (!mounted) return;
      context.read<ShellController>().reset();
      Navigator.pushNamedAndRemoveUntil(
        context,
        trader.status == VerificationStatus.verified ? Routes.home : Routes.verificationPending,
        (_) => false,
      );
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
      showBack: false,
      title: 'تسجيل الدخول',
      subtitle: 'أهلًا بك في FreshRoute AI',
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: _id,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.emailOrPhone,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني أو رقم الهاتف', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 14),
          PasswordField(controller: _pass, validator: (v) => (v == null || v.isEmpty) ? 'كلمة المرور مطلوبة' : null),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: () => Navigator.pushNamed(context, Routes.forgotPassword), child: const Text('نسيت كلمة المرور؟')),
          ),
          if (_error != null) ...[
            InlineMessage(text: _error!, color: AppColors.danger, icon: Icons.error_outline),
            const SizedBox(height: 12),
          ],
          LoadingButton(label: 'دخول', loading: _loading, onPressed: _submit),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('ليس لديك حساب؟', style: t.bodyMedium),
            TextButton(onPressed: () => Navigator.pushNamed(context, Routes.register), child: const Text('سجّل كتاجر')),
          ]),
        ]),
      ),
    );
  }
}
