import 'package:flutter/material.dart';
import '../dialogs/privacy_policy_dialog.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFFAF9F5);
  static const Color accentColor = Color(0xFFFEF3C7);

  void openRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  void openLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PrivacyPolicyDialog(),
    );
  }

  void _showHowItWorksModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'How READ-EE Works',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModalStep(
                    number: '1',
                    icon: Icons.mic_rounded,
                    title: '1. Oral Reading Aloud',
                    description:
                        'The student reads an assigned reading passage aloud into the app.',
                  ),
                  const SizedBox(height: 12),
                  _buildModalStep(
                    number: '2',
                    icon: Icons.graphic_eq_rounded,
                    title: '2. Speech Recognition & Fluency',
                    description:
                        'Whisper speech recognition evaluates word-by-word reading accuracy and reading speed (WPM) with background noise filtering.',
                  ),
                  const SizedBox(height: 12),
                  _buildModalStep(
                    number: '3',
                    icon: Icons.quiz_outlined,
                    title: '3. Comprehension Assessment',
                    description:
                        'The student answers multiple-choice comprehension questions to measure text understanding.',
                  ),
                  const SizedBox(height: 12),
                  _buildModalStep(
                    number: '4',
                    icon: Icons.psychology_rounded,
                    title: '4. Difficulty Classification & Reading Profile',
                    description:
                        'The system classifies the student\'s reading difficulty (Decoding, Fluency, Comprehension, or Normal) and determines their official Reading Profile (Independent, Instructional, or Frustration).',
                  ),
                  const SizedBox(height: 12),
                  _buildModalStep(
                    number: '5',
                    icon: Icons.verified_user_outlined,
                    title: '5. Teacher Verification & Recording',
                    description:
                        'The teacher reviews flagged reading differences and verifies the final results, updating the student\'s persistent record.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('GOT IT'),
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildModalStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'READ-EE',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => openLogin(context),
            child: const Text(
              'Teacher Login',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 720,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Text(
                    'ORAL READING ASSESSMENT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(
                        text: 'READ. ',
                        style: TextStyle(color: textPrimary),
                      ),
                      TextSpan(
                        text: 'ASSESS. ',
                        style: TextStyle(
                          color: Color(0xFFD97706),
                        ),
                      ),
                      TextSpan(
                        text: 'GROW.',
                        style: TextStyle(
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'An oral reading assessment tool designed for Grade 4-6 Filipino learners to help teachers assess reading accuracy, speed, and comprehension, identify specific reading difficulties, and provide targeted reading support.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.65,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 38),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => openRegister(context),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: const Text('GET STARTED'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: textPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _showHowItWorksModal(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textPrimary,
                        side: const BorderSide(
                          color: textPrimary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'How READ-EE Works',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                TextButton(
                  onPressed: () => _showPrivacyPolicy(context),
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
