import 'package:flutter/material.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) Navigator.pushReplacementNamed(context, Routes.login);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutBack,
            builder: (_, s, child) => Transform.scale(scale: s, child: child),
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
              BrandLogo(size: 96, light: true),
              SizedBox(height: 20),
              BrandTitle(light: true),
              SizedBox(height: 32),
              SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.sky)),
            ]),
          ),
        ),
      );
}
