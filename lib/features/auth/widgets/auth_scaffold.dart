import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand.dart';

/// Shared layout for authentication screens: brand header + scrollable card body.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, this.subtitle, required this.child, this.showBack = true, this.bottom});
  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: showBack ? AppBar(backgroundColor: AppColors.background) : null,
      bottomNavigationBar: bottom,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: BrandLogo(size: 64)),
                  const SizedBox(height: 16),
                  Text(title, style: t.headlineMedium, textAlign: TextAlign.center),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(subtitle!, style: t.bodyMedium?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Password field with a show / hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required this.controller, this.label = 'كلمة المرور', this.validator, this.textInputAction});
  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controller,
        obscureText: _hidden,
        validator: widget.validator,
        textInputAction: widget.textInputAction,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            tooltip: _hidden ? 'إظهار' : 'إخفاء',
            icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _hidden = !_hidden),
          ),
        ),
      );
}
