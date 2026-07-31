import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'package:home_widget/home_widget.dart';
import 'screens/splash_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/wallet_service.dart';

String? passwordResetTokenFromRoute(String? routeName) {
  if (routeName == null) return null;
  final uri = Uri.tryParse(routeName);
  if (uri == null) return null;
  final isResetRoute = uri.path == '/reset-password' ||
      (uri.scheme == 'nala' && uri.host == 'reset-password');
  if (!isResetRoute) return null;
  final token = uri.queryParameters['token'];
  return token == null || token.isEmpty ? null : token;
}

String? emailVerificationTokenFromRoute(String? routeName) {
  if (routeName == null) return null;
  final uri = Uri.tryParse(routeName);
  if (uri == null) return null;
  final isVerificationRoute = uri.path == '/verify-email' ||
      (uri.scheme == 'nala' && uri.host == 'verify-email');
  if (!isVerificationRoute) return null;
  final token = uri.queryParameters['token'];
  return token == null || token.isEmpty ? null : token;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) HomeWidget.setAppGroupId('group.nala');

  runApp(
    // Setup Provider at the highest level
    MultiProvider(
      providers: [
        // Add your providers here later, e.g. AuthProvider, FinanceProvider
        Provider(create: (_) => ()),
      ],
      child: const NalaApp(),
    ),
  );
}

class NalaApp extends StatefulWidget {
  const NalaApp({super.key});

  @override
  State<NalaApp> createState() => _NalaAppState();
}

class _NalaAppState extends State<NalaApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    ApiSession.expired.addListener(_handleExpiredSession);
  }

  @override
  void dispose() {
    ApiSession.expired.removeListener(_handleExpiredSession);
    super.dispose();
  }

  void _handleExpiredSession() {
    if (!ApiSession.expired.value) return;
    ApiSession.expired.value = false;
    WalletService.clearCache();
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'NALA Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        final resetToken = passwordResetTokenFromRoute(settings.name);
        if (resetToken != null) {
          return MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(token: resetToken),
            settings: settings,
          );
        }
        final verificationToken =
            emailVerificationTokenFromRoute(settings.name);
        return verificationToken == null
            ? null
            : MaterialPageRoute(
                builder: (_) => VerifyEmailScreen(token: verificationToken),
                settings: settings,
              );
      },
    );
  }
}
