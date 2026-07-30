import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'package:home_widget/home_widget.dart';
import 'screens/splash_screen.dart';
import 'screens/reset_password_screen.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.setAppGroupId('group.nala');

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

class NalaApp extends StatelessWidget {
  const NalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NALA Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        final token = passwordResetTokenFromRoute(settings.name);
        return token == null
            ? null
            : MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(token: token),
                settings: settings,
              );
      },
    );
  }
}
