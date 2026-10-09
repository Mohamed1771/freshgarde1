import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/shell_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../shared/repositories/auth_repository.dart';
import 'widgets/auth_scaffold.dart';

class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  bool _loading = false;

  Future<void> _approve() async {
    setState(() => _loading = true);
    await context.read<AuthRepository>().approveCurrentDemo();
    if (!mounted) return;
    context.read<ShellController>().reset();
    Navigator.pushNamedAndRemoveUntil(context, Routes.home, (_) => false);
    Toast.success(context, 'تم توثيق الحساب (محاكاة لموافقة الإدارة)');
  }

  void _logout() {
    context.read<AuthRepository>().logout();
    Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final trader = context.watch<AuthRepository>().currentTrader;
    final t = Theme.of(context).textTheme;
    Widget step(IconData i, String title, String sub, Color c, {bool done = false}) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: c.withValues(alpha: 0.12), child: Icon(done ? Icons.check : i, color: c)),
          title: Text(title, style: t.titleSmall),
          subtitle: Text(sub, style: t.bodySmall),
        );

    return AuthScaffold(
      showBack: false,
      title: 'حسابك قيد التحقق',
      subtitle: 'نراجع وثائق منشأتك عادةً خلال 1–2 يوم عمل',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppCard(
          child: Column(children: [
            step(Icons.person_add_alt, 'إنشاء الحساب', trader?.fullName ?? '', AppColors.success, done: true),
            step(Icons.upload_file, 'رفع الوثائق', '${trader?.documents.length ?? 0} وثيقة مرفقة', AppColors.success, done: true),
            step(Icons.hourglass_top, 'مراجعة الإدارة', 'قيد المراجعة', AppColors.warning),
            step(Icons.verified_outlined, 'تفعيل الحساب', 'بانتظار المراجعة', AppColors.textMuted),
          ]),
        ),
        const SizedBox(height: 16),
        const InlineMessage(
          text: 'في النسخة التجريبية يمكنك محاكاة موافقة الإدارة للمتابعة إلى التطبيق.',
          color: AppColors.warning,
          icon: Icons.science_outlined,
        ),
        const SizedBox(height: 16),
        LoadingButton(label: 'محاكاة الموافقة والمتابعة', icon: Icons.verified, loading: _loading, onPressed: _approve),
        const SizedBox(height: 10),
        TextButton(onPressed: _logout, child: const Text('تسجيل الخروج')),
      ]),
    );
  }
}
