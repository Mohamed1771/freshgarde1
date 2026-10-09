import 'package:flutter/material.dart';

import '../../features/ai_inspection/ai_inspection_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/verification_pending_screen.dart';
import '../../features/dashboard/main_shell.dart';
import '../../features/deals/deals_screen.dart';
import '../../features/export/create_shipment_screen.dart';
import '../../features/marketplace/deal_request_screen.dart';
import '../../features/marketplace/offer_details_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/help_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shipments/shipment_details_screen.dart';

/// Named routes. Arguments are plain IDs so screens always read fresh data from repositories.
abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const otp = '/otp';
  static const resetPassword = '/reset-password';
  static const verificationPending = '/verification-pending';
  static const home = '/home';
  static const offerDetails = '/offer';
  static const dealRequest = '/deal-request';
  static const createShipment = '/export/create';
  static const shipmentDetails = '/shipment';
  static const aiInspection = '/ai-inspection';
  static const simulation = '/simulation';
  static const notifications = '/notifications';
  static const deals = '/deals';
  static const reports = '/reports';
  static const editProfile = '/profile/edit';
  static const settings = '/settings';
  static const help = '/help';

  static Route<dynamic> onGenerate(RouteSettings s) {
    final arg = s.arguments;
    final Widget page = switch (s.name) {
      splash => const SplashScreen(),
      login => const LoginScreen(),
      register => const RegisterScreen(),
      forgotPassword => const ForgotPasswordScreen(),
      otp => const OtpScreen(),
      resetPassword => const ResetPasswordScreen(),
      verificationPending => const VerificationPendingScreen(),
      home => const MainShell(),
      offerDetails => OfferDetailsScreen(offerId: arg as String),
      dealRequest => DealRequestScreen(offerId: arg as String),
      createShipment => const CreateShipmentScreen(),
      shipmentDetails => ShipmentDetailsScreen(shipmentId: arg as String?),
      aiInspection => AiInspectionScreen(shipmentId: arg as String?),
      // The simulation is part of the live shipment view.
      simulation => ShipmentDetailsScreen(shipmentId: arg as String?),
      notifications => const NotificationsScreen(),
      deals => const DealsScreen(standalone: true),
      reports => const ReportsScreen(),
      editProfile => const EditProfileScreen(),
      settings => const SettingsScreen(),
      help => const HelpScreen(),
      _ => const SplashScreen(),
    };
    return MaterialPageRoute(builder: (_) => page, settings: s);
  }
}
