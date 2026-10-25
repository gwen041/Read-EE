import 'package:flutter/material.dart';
import '../models/class_section.dart';
import 'students_screen.dart';
import '../dialogs/add_class_dialog.dart';

class ClassesScreen extends StatefulWidget {
  final List<ClassSection> classes;

  const ClassesScreen({
    super.key,
    required this.classes,
  });

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFFAF9F5);
  static const Color accentColor = Color(0xFFFEF3C7);

  String _selectedGrade = 'Grade 4';

  @override
  void initState() {
    super.initState();
    final grades = availableGrades;
    if (!grades.contains(_selectedGrade) && grades.isNotEmpty) {
      _selectedGrade = grades.first;
    }
  }

  String _normalizeGrade(String raw) {
    final trimmed = raw.trim();
    if (trimmed.toLowerCase().startsWith('grade')) {
      return trimmed;
    }
    return 'Grade $trimmed';
  }

  Map<String, List<ClassSection>> get groupedClasses {
    final Map<String, List<ClassSection>> grouped = {};
    for (final c in widget.classes) {
      final grade = _normalizeGrade(c.gradeLevel);
      grouped.putIfAbsent(grade, () => []).add(c);
    }
    return grouped;
  }

  List<String> get availableGrades {
    final set = <String>{'Grade 4', 'Grade 5', 'Grade 6'};
    for (final c in widget.classes) {
      set.add(_normalizeGrade(c.gradeLevel));
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  Future<void> addClass() async {
    final newClass = await showDialog<ClassSection>(
      context: context,
      builder: (context) {
        return AddClassDialog(
          classes: widget.classes,
        );
      },
    );

    if (newClass != null && mounted) {
      setState(() {
        widget.classes.add(newClass);
        _selectedGrade = _normalizeGrade(newClass.gradeLevel);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedClasses;
    final grades = availableGrades;
    final activeSections = grouped[_selectedGrade] ?? [];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: MediaQuery.of(context).size.width < 800,
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'My Classes',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: addClass,
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text(
                    'Add Class',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage sections and class rosters by grade level',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: grades.map((grade) {
                      final isSelected = grade == _selectedGrade;
                      final count = grouped[grade]?.length ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              _selectedGrade = grade;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  grade,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected ? textPrimary : textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? accentColor
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? textPrimary
                                          : textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 18),

                Expanded(
                  child: activeSections.isEmpty
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.groups_rounded,
                                    size: 32,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No sections for $_selectedGrade yet',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Click "+ Add Class" to create your first section.',
                                  style: TextStyle(
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
                            if (constraints.maxWidth >= 600) {
                              return GridView.builder(
                                itemCount: activeSections.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: 82,
                                ),
                                itemBuilder: (context, index) {
                                  return _buildClassCard(activeSections[index]);
                                },
                              );
                            }
                            return ListView.separated(
                              itemCount: activeSections.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                return _buildClassCard(activeSections[index]);
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

  Widget _buildClassCard(ClassSection classSection) {
    final studentCount = classSection.students.length;
    final displayName = classSection.sectionName.startsWith('Section')
        ? classSection.sectionName
        : 'Section ${classSection.sectionName}';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentsScreen(
                classSection: classSection,
              ),
            ),
          );
          setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Color(0xFF3B82F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Tap to view class roster & assess students',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$studentCount ${studentCount == 1 ? "student" : "students"}',
                  style: const TextStyle(
                    color: Color(0xFF047857),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
