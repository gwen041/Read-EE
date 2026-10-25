import 'package:flutter/material.dart';
import '../models/assessment.dart';
import '../models/class_section.dart';
import '../services/assessment_service.dart';
import '../services/auth_service.dart';
import '../services/class_service.dart';
import 'materials_screen.dart';
import 'reading_screen.dart';
import 'assessments_screen.dart';
import 'classes_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final List<ClassSection>? classes;

  const DashboardScreen({
    super.key,
    this.classes,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ClassSection> _classes = [];
  List<Assessment> _assessments = [];
  bool _isLoading = true;
  int _currentTabIndex = 0;

  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFFAF9F5);
  static const Color accentColor = Color(0xFFFEF3C7);

  @override
  void initState() {
    super.initState();
    if (widget.classes != null && widget.classes!.isNotEmpty) {
      _classes = widget.classes!;
      _isLoading = false;
      _loadDashboardData(showSpinner: false);
    } else {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() => _isLoading = true);
    }
    try {
      final fetchedClasses = await ClassService.getClasses();
      final fetchedAssessments = await AssessmentService.getAssessments();
      if (!mounted) return;
      setState(() {
        _classes = fetchedClasses;
        _assessments = fetchedAssessments;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int get totalStudents {
    int total = 0;
    for (final classSection in _classes) {
      total += classSection.students.length;
    }
    return total;
  }

  int get totalAssessments => _assessments.length;

  int get todayAssessmentsCount {
    final now = DateTime.now();
    return _assessments.where((a) {
      return a.date.year == now.year &&
          a.date.month == now.month &&
          a.date.day == now.day;
    }).length;
  }

  int get uniqueAssessedStudentsCount {
    final names = _assessments
        .map((a) => a.studentName.trim().toLowerCase())
        .where((n) => n.isNotEmpty && n != 'unknown student')
        .toSet();
    return names.length;
  }

  int get assessmentProgressPercent {
    if (totalStudents == 0) return 0;
    return ((uniqueAssessedStudentsCount / totalStudents) * 100).round().clamp(0, 100);
  }

  Map<String, int> get readingProfilesCount {
    int indep = 0;
    int inst = 0;
    int frust = 0;
    for (final a in _assessments) {
      final profile = Assessment.getReadingProfile(a.accuracy, a.comprehension);
      if (profile == 'Independent') {
        indep++;
      } else if (profile == 'Instructional') {
        inst++;
      } else {
        frust++;
      }
    }
    return {'Independent': indep, 'Instructional': inst, 'Frustration': frust};
  }

  Map<String, int> get classificationsCount {
    int normal = 0;
    int decoding = 0;
    int fluency = 0;
    int comp = 0;
    for (final a in _assessments) {
      final key = a.classification.toLowerCase().trim();
      if (key.contains('normal')) {
        normal++;
      } else if (key.contains('decod')) {
        decoding++;
      } else if (key.contains('fluen')) {
        fluency++;
      } else if (key.contains('comprehen')) {
        comp++;
      } else {
        normal++;
      }
    }
    return {
      'Normal': normal,
      'Decoding': decoding,
      'Fluency': fluency,
      'Comprehension': comp,
    };
  }

  Map<String, List<ClassSection>> get classesByGrade {
    final map = <String, List<ClassSection>>{};
    for (final c in _classes) {
      String grade = c.gradeLevel.trim();
      if (!grade.toLowerCase().startsWith('grade')) {
        grade = 'Grade $grade';
      }
      map.putIfAbsent(grade, () => []).add(c);
    }
    return map;
  }

  void _selectTab(int index) {
    if (_currentTabIndex == index) return;
    setState(() {
      _currentTabIndex = index;
    });
    if (index == 0) {
      _loadDashboardData(showSpinner: false);
    }
  }

  Widget _buildCurrentTab() {
    switch (_currentTabIndex) {
      case 1:
        return ClassesScreen(
          key: ValueKey('classes_${_classes.length}'),
          classes: _classes,
        );
      case 2:
        return const MaterialsScreen();
      case 3:
        return const AssessmentsScreen();
      default:
        return _buildMainDashboardContent();
    }
  }

  Future<void> openClasses() async {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;
    if (isWideScreen) {
      _selectTab(1);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassesScreen(
          classes: _classes,
        ),
      ),
    );
    _loadDashboardData(showSpinner: false);
  }

  Future<void> openReadingAssessment() async {
    if (_classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one class and student first.'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingScreen(
          classes: _classes,
        ),
      ),
    );
    _loadDashboardData(showSpinner: false);
  }

  void openMaterials() {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;
    if (isWideScreen) {
      _selectTab(2);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MaterialsScreen(),
      ),
    );
  }

  Future<void> openAssessments() async {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;
    if (isWideScreen) {
      _selectTab(3);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AssessmentsScreen(),
      ),
    );
    _loadDashboardData(showSpinner: false);
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Are you sure you want to log out of READ-EE?',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          handleLogout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
      },
    );
  }

  void handleLogout() {
    AuthService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showClassesBreakdownModal() {
    final grouped = classesByGrade;
    final gradeKeys = grouped.keys.toList();
    String? selectedGrade = gradeKeys.isNotEmpty ? gradeKeys.first : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeSections = selectedGrade != null ? (grouped[selectedGrade] ?? []) : [];

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.class_outlined,
                              color: Color(0xFF3B82F6),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Classes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  '${_classes.length} total ${_classes.length == 1 ? "section" : "sections"} • $totalStudents students',
                                  style: const TextStyle(fontSize: 11, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: textSecondary),
                            onPressed: () => Navigator.pop(context),
                            splashRadius: 16,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_classes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No classes created yet.',
                              style: TextStyle(color: textSecondary, fontSize: 13),
                            ),
                          ),
                        )
                      else ...[

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: gradeKeys.map((grade) {
                              final isSelected = grade == selectedGrade;
                              final count = grouped[grade]?.length ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    setModalState(() {
                                      selectedGrade = grade;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? primaryColor : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$grade ($count)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? textPrimary : textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          constraints: const BoxConstraints(minHeight: 80, maxHeight: 180),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF9F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: activeSections.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'No sections in this grade.',
                                      style: TextStyle(color: textSecondary, fontSize: 12),
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Column(
                                    children: activeSections.asMap().entries.map((item) {
                                      final isLast = item.key == activeSections.length - 1;
                                      final section = item.value;
                                      final displayName = section.sectionName.startsWith('Section')
                                          ? section.sectionName
                                          : 'Section ${section.sectionName}';

                                      return Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  margin: const EdgeInsets.only(left: 4, right: 10),
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF3B82F6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    displayName,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    '${section.students.length} ${section.students.length == 1 ? "student" : "students"}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF047857),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isLast)
                                            const Divider(
                                              height: 1,
                                              thickness: 1,
                                              color: Color(0xFFE2E8F0),
                                            ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            openClasses();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          child: const Text(
                            'MANAGE CLASSES',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAssessmentsBreakdownModal() {
    final total = totalAssessments;
    final today = todayAssessmentsCount;
    final verified = _assessments.where((a) => a.isVerified).length;

    double avgAccuracy = 0;
    double avgWpm = 0;
    double avgComp = 0;

    if (total > 0) {
      final sumAcc = _assessments.fold<double>(0, (sum, a) => sum + a.accuracy);
      final sumWpm = _assessments.fold<double>(0, (sum, a) => sum + a.wpm);
      final sumComp = _assessments.fold<double>(0, (sum, a) => sum + a.comprehension);
      avgAccuracy = sumAcc / total;
      avgWpm = sumWpm / total;
      avgComp = sumComp / total;
    }

    final latestAssessment = _assessments.isNotEmpty ? _assessments.first : null;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assessment_rounded,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assessments Overview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'High-level summary of oral reading records',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: textSecondary),
                        onPressed: () => Navigator.pop(context),
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOverviewStatTile(
                          label: 'Total Sessions',
                          value: '$total',
                          color: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFEF3C7),
                          icon: Icons.assignment_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOverviewStatTile(
                          label: "Today's Sessions",
                          value: '$today',
                          color: const Color(0xFF059669),
                          bgColor: const Color(0xFFD1FAE5),
                          icon: Icons.today_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOverviewStatTile(
                          label: 'Verified',
                          value: '$verified',
                          color: const Color(0xFF2563EB),
                          bgColor: const Color(0xFFDBEAFE),
                          icon: Icons.verified_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (total > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF9F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AVERAGE READING PERFORMANCE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildOverviewMetricChip(
                                  label: 'Accuracy',
                                  value: '${avgAccuracy.toStringAsFixed(1)}%',
                                  sublabel: Assessment.getWordReadingLevel(avgAccuracy),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: const Color(0xFFE2E8F0),
                              ),
                              Expanded(
                                child: _buildOverviewMetricChip(
                                  label: 'Speed',
                                  value: '${avgWpm.round()}',
                                  sublabel: 'WPM',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: const Color(0xFFE2E8F0),
                              ),
                              Expanded(
                                child: _buildOverviewMetricChip(
                                  label: 'Comprehension',
                                  value: '${avgComp.round()}%',
                                  sublabel: Assessment.getComprehensionLevel(avgComp),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (latestAssessment != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: accentColor,
                              child: Text(
                                latestAssessment.studentName.isNotEmpty
                                    ? latestAssessment.studentName[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          latestAssessment.studentName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '• Latest',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    latestAssessment.materialTitle.isNotEmpty
                                        ? latestAssessment.materialTitle
                                        : 'Reading Material',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildOverviewProfileBadge(latestAssessment.readingProfile),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF9F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 32,
                            color: textSecondary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No Assessments Yet',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Select a student to conduct your first reading assessment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        openAssessments();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'VIEW ASSESSMENT HISTORY',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewStatTile({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetricChip({
    required String label,
    required String value,
    required String sublabel,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          sublabel,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewProfileBadge(String profile) {
    Color bg;
    Color fg;
    if (profile == 'Independent') {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF047857);
    } else if (profile == 'Instructional') {
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF1D4ED8);
    } else {
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFFC2410C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        profile,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildBrandTitle() {
    return Row(
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
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'READ-EE',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            fontSize: 19,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isActive ? textPrimary : textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? textPrimary : textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationSidebar({required bool isDrawer}) {
    final teacherName = AuthService.currentTeacher?['fullName'] ?? 'Teacher';
    final teacherEmail = AuthService.currentTeacher?['email'] ?? '';

    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _buildBrandTitle(),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 10),

            _buildSidebarItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              isActive: isDrawer ? false : _currentTabIndex == 0,
              onTap: () {
                if (isDrawer) {
                  Navigator.pop(context);
                  _selectTab(0);
                } else {
                  _selectTab(0);
                }
              },
            ),
            _buildSidebarItem(
              icon: Icons.groups_rounded,
              label: 'My Classes',
              isActive: isDrawer ? false : _currentTabIndex == 1,
              onTap: () {
                if (isDrawer) {
                  Navigator.pop(context);
                  openClasses();
                } else {
                  _selectTab(1);
                }
              },
            ),
            _buildSidebarItem(
              icon: Icons.menu_book_rounded,
              label: 'Reading Materials',
              isActive: isDrawer ? false : _currentTabIndex == 2,
              onTap: () {
                if (isDrawer) {
                  Navigator.pop(context);
                  openMaterials();
                } else {
                  _selectTab(2);
                }
              },
            ),
            _buildSidebarItem(
              icon: Icons.history_rounded,
              label: 'Assessment History',
              isActive: isDrawer ? false : _currentTabIndex == 3,
              onTap: () {
                if (isDrawer) {
                  Navigator.pop(context);
                  openAssessments();
                } else {
                  _selectTab(3);
                }
              },
            ),

            const Spacer(),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: accentColor,
                      child: Text(
                        teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          if (teacherEmail.isNotEmpty)
                            Text(
                              teacherEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 17,
                        color: Color(0xFFEF4444),
                      ),
                      tooltip: 'Log Out',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (isDrawer) Navigator.pop(context);
                        _confirmLogout();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  Widget _buildClassificationMetricCard({
    required String label,
    required int count,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainDashboardContent() {
    final teacherName = AuthService.currentTeacher?['fullName'] ?? 'Teacher';
    final profiles = readingProfilesCount;
    final classifications = classificationsCount;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 840;

            final difficultyCard = Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Difficulty Classification',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Primary reading difficulty diagnosed via Decision Tree model',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildClassificationMetricCard(
                          label: 'Normal',
                          count: classifications['Normal'] ?? 0,
                          color: const Color(0xFF10B981),
                          bg: const Color(0xFFECFDF5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildClassificationMetricCard(
                          label: 'Decoding',
                          count: classifications['Decoding'] ?? 0,
                          color: const Color(0xFF3B82F6),
                          bg: const Color(0xFFEFF6FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildClassificationMetricCard(
                          label: 'Fluency',
                          count: classifications['Fluency'] ?? 0,
                          color: const Color(0xFFF59E0B),
                          bg: const Color(0xFFFFFBEB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildClassificationMetricCard(
                          label: 'Comprehension',
                          count: classifications['Comprehension'] ?? 0,
                          color: const Color(0xFFEF4444),
                          bg: const Color(0xFFFEF2F2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

            final profilesCard = Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phil-IRI Reading Profiles',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Word reading and comprehension profile levels',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildProfileItem(
                          label: 'Independent Level',
                          count: profiles['Independent'] ?? 0,
                          color: const Color(0xFF10B981),
                        ),
                        const Divider(height: 12, thickness: 1, color: Color(0xFFE2E8F0)),
                        _buildProfileItem(
                          label: 'Instructional Level',
                          count: profiles['Instructional'] ?? 0,
                          color: const Color(0xFFD97706),
                        ),
                        const Divider(height: 12, thickness: 1, color: Color(0xFFE2E8F0)),
                        _buildProfileItem(
                          label: 'Frustration Level',
                          count: profiles['Frustration'] ?? 0,
                          color: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );

            final actionButton = SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: openClasses,
                icon: const Icon(Icons.groups_rounded, size: 20),
                label: const Text(
                  'SELECT STUDENT TO ASSESS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $teacherName!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Oral Reading Assessment & Difficulty Classifier',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.class_outlined,
                          title: 'Classes',
                          value: '${_classes.length}',
                          subtitle: _classes.length == 1
                              ? '1 Section'
                              : '${_classes.length} Sections',
                          iconColor: const Color(0xFF3B82F6),
                          onTap: _showClassesBreakdownModal,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.assignment_turned_in_outlined,
                          title: 'Assessments',
                          value: '$totalAssessments',
                          subtitle: todayAssessmentsCount > 0
                              ? '$todayAssessmentsCount Today'
                              : '0 Today',
                          iconColor: const Color(0xFFD97706),
                          onTap: _showAssessmentsBreakdownModal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isDesktop) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: difficultyCard),
                        const SizedBox(width: 16),
                        Expanded(child: profilesCard),
                      ],
                    ),
                    const SizedBox(height: 16),
                    actionButton,
                  ] else ...[
                    difficultyCard,
                    const SizedBox(height: 16),
                    profilesCard,
                    const SizedBox(height: 18),
                    actionButton,
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: isWideScreen ? null : Drawer(child: _buildNavigationSidebar(isDrawer: true)),
      appBar: isWideScreen
          ? null
          : AppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: textPrimary),
                  tooltip: 'Open Menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: _buildBrandTitle(),
            ),
      body: Row(
        children: [
          if (isWideScreen) _buildNavigationSidebar(isDrawer: false),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (isWideScreen
                    ? _buildCurrentTab()
                    : _buildMainDashboardContent()),
          ),
        ],
      ),
    );
  }
}
