import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/assessment.dart';

class AssessmentDetailsDialog extends StatelessWidget {
  final Assessment assessment;
  final String Function(DateTime date) formatDateTime;
  final void Function(Assessment assessment) onVerifyRequest;
  final void Function(Assessment assessment) onDeleteRequest;

  const AssessmentDetailsDialog({
    super.key,
    required this.assessment,
    required this.formatDateTime,
    required this.onVerifyRequest,
    required this.onDeleteRequest,
  });

  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color accentColor = Color(0xFFFEF3C7);

  static Color getProfileColor(String profile) {
    switch (profile.toLowerCase().trim()) {
      case 'independent':
        return const Color(0xFF047857);
      case 'frustration':
        return const Color(0xFFB91C1C);
      case 'instructional':
      default:
        return const Color(0xFFB45309);
    }
  }

  static Color getProfileBg(String profile) {
    switch (profile.toLowerCase().trim()) {
      case 'independent':
        return const Color(0xFFECFDF5);
      case 'frustration':
        return const Color(0xFFFEE2E2);
      case 'instructional':
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  static Color getClassificationColor(String classification) {
    switch (classification.toLowerCase().trim()) {
      case 'decoding':
        return const Color(0xFF6D28D9);
      case 'fluency':
        return const Color(0xFF1D4ED8);
      case 'comprehension':
        return const Color(0xFFC2410C);
      case 'normal':
      default:
        return const Color(0xFF047857);
    }
  }

  static Color getClassificationBg(String classification) {
    switch (classification.toLowerCase().trim()) {
      case 'decoding':
        return const Color(0xFFF5F3FF);
      case 'fluency':
        return const Color(0xFFEFF6FF);
      case 'comprehension':
        return const Color(0xFFFFF7ED);
      case 'normal':
      default:
        return const Color(0xFFECFDF5);
    }
  }

  static Color getClassificationBorder(String classification) {
    switch (classification.toLowerCase().trim()) {
      case 'decoding':
        return const Color(0xFFDDD6FE);
      case 'fluency':
        return const Color(0xFFBFDBFE);
      case 'comprehension':
        return const Color(0xFFFED7AA);
      case 'normal':
      default:
        return const Color(0xFFA7F3D0);
    }
  }

  static IconData getClassificationIcon(String classification) {
    switch (classification.toLowerCase().trim()) {
      case 'decoding':
        return Icons.abc_rounded;
      case 'fluency':
        return Icons.record_voice_over_outlined;
      case 'comprehension':
        return Icons.auto_stories_rounded;
      case 'normal':
      default:
        return Icons.task_alt_rounded;
    }
  }

  static String getClassificationLabel(String classification) {
    final lower = classification.toLowerCase().trim();
    if (lower == 'normal') return 'NORMAL READING';
    if (lower.contains('difficulty')) return classification.toUpperCase();
    return '${classification.toUpperCase()} DIFFICULTY';
  }

  static String getShortClassificationLabel(String classification) {
    final lower = classification.toLowerCase().trim();
    if (lower == 'normal') return 'NORMAL';
    if (lower.startsWith('decoding')) return 'DECODING';
    if (lower.startsWith('fluency')) return 'FLUENCY';
    if (lower.startsWith('comprehension')) return 'COMPREHENSION';
    return classification
        .toUpperCase()
        .replaceAll('DIFFICULTY', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(size.width * 0.95, 680.0);
    final dialogHeight = math.min(size.height * 0.90, 840.0);

    final classColor = getClassificationColor(assessment.displayClassification);
    final classBg = getClassificationBg(assessment.displayClassification);
    final classBorder = getClassificationBorder(assessment.displayClassification);
    final classIcon = getClassificationIcon(assessment.displayClassification);

    final profileColor = getProfileColor(assessment.readingProfile);
    final profileBg = getProfileBg(assessment.readingProfile);

    return Dialog(
      backgroundColor: const Color(0xFFFAF9F5),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: accentColor,
                    child: Text(
                      assessment.studentName.isNotEmpty
                          ? assessment.studentName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assessment.studentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (assessment.gradeAndSection.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  assessment.gradeAndSection.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            Text(
                              formatDateTime(assessment.date),
                              style: const TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_rounded,
                      color: Color(0xFFDC2626),
                      size: 22,
                    ),
                    tooltip: 'Delete Assessment',
                    onPressed: () => _confirmAndDelete(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            size: 18,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'READING MATERIAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  assessment.materialTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildFinalTopCard(
                              title: 'ACCURACY',
                              value:
                                  '${assessment.accuracy.toStringAsFixed(1)}%',
                              subtitle:
                                  'Initial: ${assessment.initialAccuracy.toStringAsFixed(1)}%',
                              icon: Icons.fact_check_outlined,
                              iconColor: const Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildFinalTopCard(
                              title: 'READING SPEED',
                              value:
                                  '${assessment.wpm.toStringAsFixed(1)} WPM',
                              subtitle:
                                  'Initial: ${(assessment.initialWpm ?? assessment.wpm).toStringAsFixed(1)} WPM',
                              icon: Icons.timer_outlined,
                              iconColor: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildFinalTopCard(
                              title: 'COMPREHENSION',
                              value: '${assessment.comprehension.round()}%',
                              subtitle:
                                  'Initial: ${(assessment.initialComprehension ?? assessment.comprehension).round()}%',
                              icon: Icons.auto_stories_outlined,
                              iconColor: const Color(0xFFC2410C),
                            ),
                          ),
                          const SizedBox(width: 10),

                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: classBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: classBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(classIcon, size: 14, color: classColor),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'DIFFICULTY',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: classColor,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    getShortClassificationLabel(
                                        assessment.displayClassification),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: classColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    assessment.isVerified
                                        ? 'Final Verified'
                                        : 'Pending Verification',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          classColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _CollapsibleSection(
                      initiallyExpanded: true,
                      header: Row(
                        children: [
                          Icon(
                            assessment.isVerified
                                ? Icons.verified_rounded
                                : Icons.pending_actions_rounded,
                            size: 18,
                            color: assessment.isVerified
                                ? const Color(0xFF047857)
                                : const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              assessment.isVerified
                                  ? 'Final Verified Result'
                                  : 'Final Result (Pending Verification)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: assessment.isVerified
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              assessment.isVerified ? 'VERIFIED' : 'PENDING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: assessment.isVerified
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: classBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: classBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(classIcon,
                                            size: 16, color: classColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          'DIFFICULTY CLASSIFICATION',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: classColor,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(color: classBorder),
                                      ),
                                      child: Text(
                                        getShortClassificationLabel(
                                            assessment.displayClassification),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: classColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  assessment.classificationExplanation,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: profileBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: profileColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_ind_outlined,
                                      size: 16,
                                      color: profileColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'PHIL-IRI READING PROFILE',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: profileColor,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                          color: profileColor
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        assessment.readingProfile.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: profileColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  assessment.readingProfileExplanation,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (!assessment.isVerified)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.rate_review_outlined,
                                        size: 17,
                                        color: Color(0xFF1E293B),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Teacher Verification Required',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: const Text(
                                          'UNVERIFIED',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF475569),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'This assessment was confirmed without completing reading verification. Review the flagged words to finalize the student\'s reading score.',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF475569),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          onVerifyRequest(assessment),
                                      icon: const Icon(
                                        Icons.fact_check_outlined,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Verify Reading Errors',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: textPrimary,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 15,
                                  color: Color(0xFF047857),
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Teacher verified: Error decisions applied to final calculation.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF047857),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    _CollapsibleSection(
                      initiallyExpanded: false,
                      header: const Text(
                        'Initial System Assessment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Raw automated metrics captured prior to teacher verification.',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Initial Classification: ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: textSecondary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    getShortClassificationLabel(
                                        assessment.initialDisplayClassification),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: _buildInitialTile(
                                  label: 'Initial Accuracy',
                                  value:
                                      '${assessment.initialAccuracy.toStringAsFixed(1)}%',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInitialTile(
                                  label: 'Initial Speed',
                                  value:
                                      '${(assessment.initialWpm ?? assessment.wpm).toStringAsFixed(1)} WPM',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInitialTile(
                                  label: 'Initial Comp.',
                                  value:
                                      '${(assessment.initialComprehension ?? assessment.comprehension).round()}%',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInitialTile(
                                  label: 'Initial Profile',
                                  value: assessment
                                      .initialReadingProfileFormatted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (assessment.passage.isNotEmpty) ...[
                      const Text(
                        'READING PASSAGE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          assessment.passage,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  if (!assessment.isVerified) ...[
                    ElevatedButton.icon(
                      onPressed: () => onVerifyRequest(assessment),
                      icon: const Icon(Icons.fact_check_rounded, size: 16),
                      label: const Text('Verify Assessment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
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

  Future<void> _confirmAndDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text(
              'Delete Assessment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete the assessment for "${assessment.studentName}" on "${assessment.materialTitle}"?',
              style: const TextStyle(
                  fontSize: 14, color: textPrimary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone and will permanently remove this record from history.',
                      style: TextStyle(
                          fontSize: 11.5, color: Color(0xFF991B1B), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: const Text('Delete Assessment'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      onDeleteRequest(assessment);
    }
  }

  Widget _buildFinalTopCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialTile({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  final Widget header;
  final Widget child;
  final bool initiallyExpanded;

  const _CollapsibleSection({
    required this.header,
    required this.child,
    this.initiallyExpanded = true,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(child: widget.header),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: widget.child,
            ),
          ],
        ],
      ),
    );
  }
}
