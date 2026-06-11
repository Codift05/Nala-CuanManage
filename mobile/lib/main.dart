import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
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
    );
  }
}
