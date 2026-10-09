
import 'package:flutter/material.dart';

import 'screens/landing_screen.dart';

void main() {
  runApp(const ReadEEApp());
}

class ReadEEApp extends StatelessWidget {
  const ReadEEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'READ-EE',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingScreen(),
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
