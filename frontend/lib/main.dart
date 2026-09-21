import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ReadEEApp());
}

class ReadEEApp extends StatelessWidget {
  const ReadEEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'READ-EE',
      home: const LoginScreen(),
    );
  }
}