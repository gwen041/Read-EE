import 'dart:math' as math;
import 'package:flutter/material.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(size.width * 0.92, 620.0);
    final dialogHeight = math.min(size.height * 0.85, 680.0);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Last updated: October 2026',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: textSecondary),
                    splashRadius: 18,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'READ-EE is an oral reading assessment and difficulty diagnosis platform designed for elementary school teachers. This Privacy Policy describes how we handle, protect, and respect your information and your students\' data.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.6,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      title: '1. Information We Collect',
                      body:
                          'We only collect information necessary to facilitate oral reading assessments and classroom management:\n\n'
                          '• Teacher Accounts: Name, email address, and authentication credentials.\n'
                          '• Student Information: Student names, grade levels, and assigned sections.\n'
                          '• Audio Recordings: Audio captured through your device\'s microphone during reading assessment sessions.\n'
                          '• Reading Performance Data: Word accuracy scores, words per minute (WPM), reading comprehension answers, detected miscues, reading profiles, and difficulty classifications.',
                    ),
                    _buildSection(
                      title: '2. Voice Recordings & Audio Data',
                      body:
                          'Voice recordings captured during assessment sessions are processed exclusively for educational evaluation:\n\n'
                          '• Automated speech recognition processes the audio to identify word omissions, substitutions, and reading pace.\n'
                          '• Audio recordings are accessible to the student\'s teacher for listening, verification, and manual corrections.\n'
                          '• Voice data is never sold, shared with third-party advertisers, or used for commercial profiling.',
                    ),
                    _buildSection(
                      title: '3. How We Use Information',
                      body:
                          'Collected information is used solely to:\n\n'
                          '• Calculate Phil-IRI oral reading profiles and reading levels.\n'
                          '• Classify reading difficulties to help teachers provide targeted reading interventions.\n'
                          '• Maintain class rosters and student assessment history over time.',
                    ),
                    _buildSection(
                      title: '4. Data Storage and Security',
                      body:
                          '• All data transmitted between the application and backend services is encrypted using HTTPS and TLS standards.\n'
                          '• Class records and student data are isolated so that each teacher only accesses their own classes and students.\n'
                          '• Passwords and authentication credentials are encrypted using secure industry-standard hashing.',
                    ),
                    _buildSection(
                      title: '5. Your Rights and Data Control',
                      body:
                          'Educators have complete ownership and control over the data stored in READ-EE:\n\n'
                          '• Access: You may review student reading histories, scores, and audio recordings at any time.\n'
                          '• Rectification: You can update student details and override automated speech assessment results.\n'
                          '• Erasure: You can permanently delete student profiles, classes, or assessment records directly from the application.',
                    ),
                    _buildSection(
                      title: '6. Changes to This Policy',
                      body:
                          'We may update this Privacy Policy from time to time to reflect operational or regulatory updates. Any changes will be posted within the application with an updated revision date.',
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
