
import 'package:flutter/material.dart';

import 'login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const Color primaryColor = Color(0xFF2457A7);
  static const Color backgroundColor = Color(0xFFF5F8FF);
  static const Color accentColor = Color(0xFFE6EEFF);

  void openLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
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
            const Icon(
              Icons.menu_book_rounded,
              color: primaryColor,
              size: 32,
            ),
            const SizedBox(width: 10),
            const Text(
              'READ-EE',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
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
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(context),
            _buildFeatures(),
            _buildHowItWorks(),
            _buildCallToAction(context),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 45,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1100,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;

              final introduction = Column(
                crossAxisAlignment: isWide
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'A SMARTER WAY TO ASSESS READING',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Helping Teachers Understand '
                    'Every Student’s Reading.',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 38,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172B4D),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'READ-EE supports teachers in assessing '
                    'English oral reading through reading '
                    'accuracy, fluency, comprehension, and '
                    'reading difficulty classification.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: Color(0xFF596579),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: isWide
                        ? WrapAlignment.start
                        : WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => openLogin(context),
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                        ),
                        label: const Text('GET STARTED'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          Scrollable.ensureVisible(
                            context,
                            duration: const Duration(
                              milliseconds: 300,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          side: const BorderSide(
                            color: primaryColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Explore Features'),
                      ),
                    ],
                  ),
                ],
              );

              final illustration = Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 280,
                ),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: primaryColor,
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'READ. ASSESS. GROW.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Supporting meaningful reading assessment '
                      'in the classroom.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF596579),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MiniLabel(
                          icon: Icons.hearing_rounded,
                          label: 'Listen',
                        ),
                        SizedBox(width: 18),
                        _MiniLabel(
                          icon: Icons.analytics_outlined,
                          label: 'Assess',
                        ),
                        SizedBox(width: 18),
                        _MiniLabel(
                          icon: Icons.insights_rounded,
                          label: 'Review',
                        ),
                      ],
                    ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 6,
                      child: introduction,
                    ),
                    const SizedBox(width: 55),
                    Expanded(
                      flex: 5,
                      child: illustration,
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  introduction,
                  const SizedBox(height: 40),
                  illustration,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 55,
      ),
      child: Column(
        children: [
          const Text(
            'Designed for Reading Assessment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tools that help teachers review students’ '
            'oral reading performance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF596579),
            ),
          ),
          const SizedBox(height: 35),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1100,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      constraints.maxWidth > 850
                          ? 4
                          : constraints.maxWidth > 520
                              ? 2
                              : 1;

                  final features = [
                    const _FeatureCard(
                      icon: Icons.record_voice_over_rounded,
                      title: 'Reading Accuracy',
                      description:
                          'Review recognized words and identify '
                          'possible reading errors.',
                    ),
                    const _FeatureCard(
                      icon: Icons.speed_rounded,
                      title: 'Reading Fluency',
                      description:
                          'Measure reading speed using words '
                          'per minute (WPM).',
                    ),
                    const _FeatureCard(
                      icon: Icons.quiz_outlined,
                      title: 'Comprehension',
                      description:
                          'Evaluate understanding through '
                          'multiple-choice questions.',
                    ),
                    const _FeatureCard(
                      icon: Icons.assessment_outlined,
                      title: 'Classification',
                      description:
                          'Use assessment results to classify '
                          'the student’s reading performance.',
                    ),
                  ];

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: features.map((feature) {
                      return SizedBox(
                        width: (
                          constraints.maxWidth -
                          (columns - 1) * 16
                        ) / columns,
                        child: feature,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 55,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          child: Column(
            children: [
              const Text(
                'How READ-EE Works',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
              const SizedBox(height: 35),
              const Wrap(
                alignment: WrapAlignment.center,
                spacing: 30,
                runSpacing: 30,
                children: [
                  _StepItem(
                    number: '01',
                    title: 'Read',
                    description:
                        'The student reads an assigned '
                        'English passage aloud.',
                  ),
                  _StepItem(
                    number: '02',
                    title: 'Assess',
                    description:
                        'The system evaluates accuracy, '
                        'fluency, and comprehension.',
                  ),
                  _StepItem(
                    number: '03',
                    title: 'Review',
                    description:
                        'The teacher reviews the results '
                        'and reading recognition errors.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallToAction(BuildContext context) {
    return Container(
      width: double.infinity,
      color: primaryColor,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 48,
      ),
      child: Column(
        children: [
          const Text(
            'Ready to Get Started?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sign in to manage your classes and reading assessments.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () => openLogin(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'CONTINUE TO LOGIN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF172B4D),
      padding: const EdgeInsets.all(22),
      child: const Text(
        'READ-EE | Reading Assessment Support for Teachers',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniLabel({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: LandingScreen.primaryColor,
          size: 25,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: LandingScreen.primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LandingScreen.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE3EAF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 34,
            color: LandingScreen.primaryColor,
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF596579),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepItem({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: LandingScreen.accentColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: LandingScreen.primaryColor,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF596579),
            ),
          ),
        ],
      ),
    );
  }
}
