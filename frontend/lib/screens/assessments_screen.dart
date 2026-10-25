import 'package:flutter/material.dart';

import '../models/assessment.dart';
import '../services/assessment_service.dart';
import 'reading_verification_screen.dart';
import '../dialogs/assessment_details_dialog.dart';

class AssessmentsScreen extends StatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> {
  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFFAF9F5);
  static const Color accentColor = Color(0xFFFEF3C7);

  List<Assessment> _assessments = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedTab = 'Today';
  String _selectedSection = 'All';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAssessments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await AssessmentService.getAssessments();
      if (!mounted) return;
      setState(() {
        _assessments = fetched;
        _isLoading = false;

        if (_getTodayAssessments().isEmpty &&
            _getGradeAssessments(4).isNotEmpty) {
          _selectedTab = 'Grade 4';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  List<Assessment> _getTodayAssessments() {
    return _assessments.where((a) => _isToday(a.date)).toList();
  }

  List<Assessment> _getGradeAssessments(int grade) {
    return _assessments.where((a) => a.gradeLevel == grade).toList();
  }

  List<Assessment> get _assessmentsInActiveTab {
    if (_selectedTab == 'Today') {
      return _getTodayAssessments();
    } else if (_selectedTab == 'Grade 4') {
      return _getGradeAssessments(4);
    } else if (_selectedTab == 'Grade 5') {
      return _getGradeAssessments(5);
    } else if (_selectedTab == 'Grade 6') {
      return _getGradeAssessments(6);
    }
    return _assessments;
  }

  List<String> get _availableSectionsInActiveTab {
    final list = _assessmentsInActiveTab;
    final sections = <String>{};
    for (final a in list) {
      final s = a.formattedSection;
      if (s.isNotEmpty) {
        sections.add(s);
      }
    }
    return sections.toList()..sort();
  }

  List<Assessment> get _filteredAssessments {
    var list = _assessmentsInActiveTab;

    if (_selectedSection != 'All') {
      list = list.where((a) => a.formattedSection == _selectedSection).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      list = list.where((a) {
        final student = a.studentName.toLowerCase();
        final material = a.materialTitle.toLowerCase();
        final section = a.formattedSection.toLowerCase();
        final classif = a.classification.toLowerCase();
        final profile = a.readingProfile.toLowerCase();
        return student.contains(query) ||
            material.contains(query) ||
            section.contains(query) ||
            classif.contains(query) ||
            profile.contains(query);
      }).toList();
    }

    return list;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour =
        date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  String _formatRelativeTime(DateTime date) {
    if (_isToday(date)) {
      return 'Today at ${_formatTime(date)}';
    }
    return '${_formatDate(date)} • ${_formatTime(date)}';
  }

  Future<Assessment?> _verifyAssessment(Assessment assessment) async {
    final accuracyData = assessment.accuracyDetails ?? {};
    final mismatches = (accuracyData['mismatch_words'] as List?) ?? [];
    final missing = (accuracyData['missing_words'] as List?) ?? [];
    final extra = (accuracyData['extra_words'] as List?) ?? [];

    final hasErrors =
        mismatches.isNotEmpty || missing.isNotEmpty || extra.isNotEmpty;

    if (!hasErrors) {
      final shouldConfirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF047857), size: 22),
              SizedBox(width: 8),
              Text(
                'Verify Assessment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'The speech recognition system did not flag any reading errors for "${assessment.studentName}".\n\n'
            'Would you like to mark this assessment as Verified?',
            style: const TextStyle(fontSize: 14, color: textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: textPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mark as Verified'),
            ),
          ],
        ),
      );

      if (shouldConfirm == true && assessment.id != null) {
        setState(() => _isLoading = true);
        try {
          final updatedAccuracyDetails = {
            ...accuracyData,
            'isVerified': true,
          };
          final updated = await AssessmentService.updateAssessment(
            assessmentId: assessment.id!,
            accuracy: assessment.accuracy,
            wpm: assessment.wpm,
            comprehensionScore: assessment.comprehension,
            classification: assessment.classification,
            accuracyDetails: updatedAccuracyDetails,
            comprehensionDetails: assessment.comprehensionDetails ?? {},
          );
          if (!mounted) return null;
          setState(() {
            final idx = _assessments.indexWhere((a) => a.id == assessment.id);
            if (idx != -1) {
              _assessments[idx] = updated;
            }
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assessment marked as verified!'),
              backgroundColor: Color(0xFF047857),
            ),
          );
          return updated;
        } catch (e) {
          if (!mounted) return null;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating verification: $e')),
          );
        }
      }
      return null;
    }

    final decisions = await Navigator.push<Map<int, bool>>(
      context,
      MaterialPageRoute(
        builder: (ctx) => ReadingVerificationScreen(
          studentName: assessment.studentName,
          materialTitle: assessment.materialTitle,
          audioPath: assessment.audioPath ?? '',
          accuracy: accuracyData,
        ),
      ),
    );

    if (decisions == null || !mounted || assessment.id == null) return null;

    setState(() => _isLoading = true);

    try {
      final finalized = await AssessmentService.finalizeAssessment(
        accuracy: accuracyData,
        wpm: {'wpm': assessment.wpm},
        comprehension: {'score': assessment.comprehension},
        decisions: decisions,
      );

      final finalAcc = (finalized['accuracy']['accuracy'] as num).toDouble();
      final finalWpm = (finalized['wpm']['wpm'] as num).toDouble();
      final finalComp = (finalized['comprehension']['score'] as num).toDouble();
      final finalClassification = finalized['classification'].toString();

      final updatedAccuracyDetails = {
        ...Map<String, dynamic>.from(finalized['accuracy']),
        'initialAccuracy': assessment.initialAccuracy,
        'initialWpm': assessment.initialWpm ?? assessment.wpm,
        'initialComprehension':
            assessment.initialComprehension ?? assessment.comprehension,
        'initialClassification':
            assessment.initialClassification ?? assessment.classification,
        'initialReadingProfile':
            assessment.initialReadingProfile ?? assessment.readingProfile,
        'audioPath': assessment.audioPath ?? '',
        'isVerified': true,
        if (finalized['reading_profile'] != null)
          'reading_profile': finalized['reading_profile'],
      };

      final updated = await AssessmentService.updateAssessment(
        assessmentId: assessment.id!,
        accuracy: finalAcc,
        wpm: finalWpm,
        comprehensionScore: finalComp,
        classification: finalClassification,
        accuracyDetails: updatedAccuracyDetails,
        comprehensionDetails: assessment.comprehensionDetails ?? {},
      );

      if (!mounted) return null;

      setState(() {
        final idx = _assessments.indexWhere((a) => a.id == assessment.id);
        if (idx != -1) {
          _assessments[idx] = updated;
        }
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reading verification completed! Final results updated.',
          ),
          backgroundColor: Color(0xFF047857),
        ),
      );

      return updated;
    } catch (e) {
      if (!mounted) return null;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update verification: $e')),
      );
      return null;
    }
  }

  Future<void> _deleteAssessment(Assessment assessment) async {
    if (assessment.id == null) return;

    setState(() => _isLoading = true);

    try {
      await AssessmentService.deleteAssessment(assessment.id!);

      if (!mounted) return;

      setState(() {
        _assessments.removeWhere((a) => a.id == assessment.id);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Assessment for "${assessment.studentName}" deleted successfully.',
          ),
          backgroundColor: const Color(0xFF1E293B),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete assessment: $e')),
      );
    }
  }

  void _openDetailsDialog(Assessment assessment) {
    showDialog(
      context: context,
      builder: (ctx) => AssessmentDetailsDialog(
        assessment: assessment,
        formatDateTime: _formatRelativeTime,
        onVerifyRequest: (toVerify) async {
          Navigator.pop(ctx);
          final updated = await _verifyAssessment(toVerify);
          if (updated != null && mounted) {
            _openDetailsDialog(updated);
          }
        },
        onDeleteRequest: (toDelete) async {
          Navigator.pop(ctx);
          await _deleteAssessment(toDelete);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayCount = _getTodayAssessments().length;
    final g4Count = _getGradeAssessments(4).length;
    final g5Count = _getGradeAssessments(5).length;
    final g6Count = _getGradeAssessments(6).length;

    final availableSections = _availableSectionsInActiveTab;
    final assessments = _filteredAssessments;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: MediaQuery.of(context).size.width < 800,
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Assessment History',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadAssessments,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: textPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildCategoryTab(
                                  label: 'Today',
                                  icon: Icons.calendar_today_rounded,
                                  count: todayCount,
                                  isSelected: _selectedTab == 'Today',
                                  onTap: () {
                                    setState(() {
                                      _selectedTab = 'Today';
                                      _selectedSection = 'All';
                                    });
                                  },
                                ),
                                _buildCategoryTab(
                                  label: 'Grade 4',
                                  count: g4Count,
                                  isSelected: _selectedTab == 'Grade 4',
                                  onTap: () {
                                    setState(() {
                                      _selectedTab = 'Grade 4';
                                      _selectedSection = 'All';
                                    });
                                  },
                                ),
                                _buildCategoryTab(
                                  label: 'Grade 5',
                                  count: g5Count,
                                  isSelected: _selectedTab == 'Grade 5',
                                  onTap: () {
                                    setState(() {
                                      _selectedTab = 'Grade 5';
                                      _selectedSection = 'All';
                                    });
                                  },
                                ),
                                _buildCategoryTab(
                                  label: 'Grade 6',
                                  count: g6Count,
                                  isSelected: _selectedTab == 'Grade 6',
                                  onTap: () {
                                    setState(() {
                                      _selectedTab = 'Grade 6';
                                      _selectedSection = 'All';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              textAlignVertical: TextAlignVertical.center,
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              style: const TextStyle(
                                fontSize: 13,
                                color: textPrimary,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText:
                                    'Search student, section, passage, or profile...',
                                hintStyle: const TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: textSecondary,
                                  size: 20,
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear_rounded,
                                          size: 18,
                                          color: textSecondary,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                suffixIconConstraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (availableSections.isNotEmpty) ...[
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildSectionPill(
                                    label: 'All Sections',
                                    count: _assessmentsInActiveTab.length,
                                    isSelected: _selectedSection == 'All',
                                    onTap: () => setState(
                                        () => _selectedSection = 'All'),
                                  ),
                                  ...availableSections.map((sec) {
                                    final count = _assessmentsInActiveTab
                                        .where((a) => a.formattedSection == sec)
                                        .length;
                                    return _buildSectionPill(
                                      label: sec,
                                      count: count,
                                      isSelected: _selectedSection == sec,
                                      onTap: () => setState(
                                          () => _selectedSection = sec),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          Expanded(
                            child: assessments.isEmpty
                                ? Center(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: const BoxDecoration(
                                              color: accentColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              _selectedTab == 'Today'
                                                  ? Icons
                                                      .calendar_today_outlined
                                                  : Icons.history_rounded,
                                              color: textPrimary,
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            _selectedTab == 'Today'
                                                ? 'No assessments recorded today'
                                                : 'No assessments found for $_selectedTab',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _searchQuery.isNotEmpty
                                                ? 'No assessments match "$_searchQuery"'
                                                : _selectedTab == 'Today'
                                                    ? 'Assessments conducted today will appear here automatically.'
                                                    : 'Assessments for this grade level will appear here once conducted.',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth >= 720) {
                                        return GridView.builder(
                                          itemCount: assessments.length,
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            mainAxisExtent: 195,
                                          ),
                                          itemBuilder: (context, index) {
                                            return _buildAssessmentSummaryCard(assessments[index]);
                                          },
                                        );
                                      }
                                      return ListView.separated(
                                        itemCount: assessments.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          return _buildAssessmentSummaryCard(assessments[index]);
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildAssessmentSummaryCard(Assessment item) {
    final profileColor = AssessmentDetailsDialog.getProfileColor(item.readingProfile);
    final profileBg = AssessmentDetailsDialog.getProfileBg(item.readingProfile);
    final classColor = AssessmentDetailsDialog.getClassificationColor(item.displayClassification);
    final classBg = AssessmentDetailsDialog.getClassificationBg(item.displayClassification);
    final classBorder = AssessmentDetailsDialog.getClassificationBorder(item.displayClassification);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: () =>
            _openDetailsDialog(item),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        accentColor,
                    child: Text(
                      item.studentName
                              .isNotEmpty
                          ? item.studentName[0]
                              .toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          item.studentName,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                textPrimary,
                          ),
                        ),
                        const SizedBox(
                            height: 2),
                        Text(
                          item.gradeAndSection
                                  .isNotEmpty
                              ? item
                                  .gradeAndSection
                              : 'Grade ${item.gradeLevel ?? "-"}',
                          style:
                              const TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .w600,
                            color:
                                textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets
                        .symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: item.isVerified
                          ? const Color(
                              0xFFECFDF5)
                          : const Color(
                              0xFFFEF3C7),
                      borderRadius:
                          BorderRadius
                              .circular(6),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          item.isVerified
                              ? Icons
                                  .verified_rounded
                              : Icons
                                  .pending_outlined,
                          size: 13,
                          color: item.isVerified
                              ? const Color(
                                  0xFF047857)
                              : const Color(
                                  0xFFB45309),
                        ),
                        const SizedBox(
                            width: 4),
                        Text(
                          item.isVerified
                              ? 'Verified'
                              : 'Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color: item
                                    .isVerified
                                ? const Color(
                                    0xFF047857)
                                : const Color(
                                    0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    color: Color(0xFF94A3B8),
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.article_outlined,
                    size: 14,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.materialTitle,
                      maxLines: 1,
                      overflow: TextOverflow
                          .ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatRelativeTime(
                        item.date),
                    style: const TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: classBg,
                  borderRadius:
                      BorderRadius.circular(
                          8),
                  border: Border.all(
                      color: classBorder),
                ),
                child: Text(
                  'CLASSIFICATION: ${AssessmentDetailsDialog.getClassificationLabel(item.displayClassification)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        FontWeight.bold,
                    color: classColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  _buildMetricChip(
                    label:
                        'Profile: ${item.readingProfile}',
                    bg: profileBg,
                    color: profileColor,
                    isBold: true,
                  ),
                  if (!item.isVerified)
                    InkWell(
                      onTap: () =>
                          _verifyAssessment(
                              item),
                      borderRadius:
                          BorderRadius
                              .circular(6),
                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              primaryColor,
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      6),
                        ),
                        child: const Row(
                          mainAxisSize:
                              MainAxisSize
                                  .min,
                          children: [
                            Icon(
                              Icons
                                  .fact_check_rounded,
                              size: 13,
                              color:
                                  textPrimary,
                            ),
                            SizedBox(
                                width: 4),
                            Text(
                              'Verify',
                              style:
                                  TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color:
                                    textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTab({
    required String label,
    IconData? icon,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: textPrimary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.35)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? textPrimary : textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionPill({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : textPrimary,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required Color bg,
    required Color color,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
