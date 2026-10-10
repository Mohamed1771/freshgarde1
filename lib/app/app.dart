import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/routing/routes.dart';
import '../core/theme/app_theme.dart';
import '../shared/repositories/auth_repository.dart';
import '../shared/repositories/notification_repository.dart';
import '../shared/repositories/offer_repository.dart';
import '../shared/repositories/settings_repository.dart';
import '../features/simulation/live_simulation_service.dart';
import '../shared/repositories/shipment_repository.dart';
import 'shell_controller.dart';

class FreshRouteApp extends StatelessWidget {
  const FreshRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationRepository()),
        ChangeNotifierProvider(create: (_) => AuthRepository()),
        ChangeNotifierProvider(create: (_) => OfferRepository()),
        ChangeNotifierProvider(create: (c) => ShipmentRepository(c.read<NotificationRepository>())),
        ChangeNotifierProvider(create: (_) => SettingsRepository()),
        Provider(
          create: (c) => LiveSimulationService(c.read<ShipmentRepository>(), c.read<SettingsRepository>()),
          dispose: (_, s) => s.dispose(),
        ),
        ChangeNotifierProvider(create: (_) => ShellController()),
      ],
      child: MaterialApp(
        title: 'FreshRoute AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('ar', 'JO'),
        supportedLocales: const [Locale('ar', 'JO'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: Routes.splash,
        onGenerateRoute: Routes.onGenerate,
      ),
    );
  }
}
