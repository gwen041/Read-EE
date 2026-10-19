import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/landing_screen.dart';
import 'services/auth_service.dart';

void main() {
  AuthService.init();
  runApp(const ReadEEApp());
}

class ReadEEApp extends StatelessWidget {
  const ReadEEApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.token != null;

    return MaterialApp(
      title: 'READ-EE',
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/dashboard' : '/',
      routes: {
        '/': (context) => const LandingScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2457A7),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
        ),
      ),
    );
  }
}