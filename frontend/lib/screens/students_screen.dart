import 'package:flutter/material.dart';

import '../models/class_section.dart';
import '../services/class_service.dart';
import 'reading_screen.dart';
import '../dialogs/add_students_dialog.dart';

class StudentsScreen extends StatefulWidget {
  final ClassSection classSection;

  const StudentsScreen({
    super.key,
    required this.classSection,
  });

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFFAF9F5);
  static const Color accentColor = Color(0xFFFEF3C7);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get sectionTitle {
    final grade = widget.classSection.gradeLevel.trim();
    final name = widget.classSection.sectionName.trim();
    final sectionFormatted = name.toLowerCase().startsWith('section')
        ? name
        : 'Section $name';
    return '$grade - $sectionFormatted';
  }

  List<StudentItem> get filteredStudents {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.classSection.students;
    }
    return widget.classSection.students
        .where((s) => s.fullName.toLowerCase().contains(query))
        .toList();
  }

  void startReadingAssessment(StudentItem student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadingScreen(
          classes: [widget.classSection],
          initialClass: widget.classSection,
          initialStudent: student,
        ),
      ),
    );
  }

  Future<void> deleteStudent(StudentItem student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Remove Student',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Are you sure you want to remove "${student.fullName}" from this section?',
                    style: const TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
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
                        onPressed: () => Navigator.pop(context, true),
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
                          'Remove',
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

    if (confirmed != true || widget.classSection.id == null) return;

    try {
      await ClassService.deleteStudent(
        classId: widget.classSection.id!,
        studentId: student.id,
      );

      setState(() {
        widget.classSection.students.removeWhere((s) => s.id == student.id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${student.fullName} was removed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void _showAddStudentsModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AddStudentsDialog(
          classSection: widget.classSection,
          onStudentsUpdated: () {
            setState(() {});
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = filteredStudents;
    final totalCount = widget.classSection.students.length;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          sectionTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          textAlignVertical: TextAlignVertical.center,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: const TextStyle(fontSize: 13, color: textPrimary),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search student by name...',
                            hintStyle: const TextStyle(fontSize: 13, color: textSecondary),
                            prefixIcon: const Icon(Icons.search_rounded, color: textSecondary, size: 20),
                            prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: textSecondary),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: _showAddStudentsModal,
                        icon: const Icon(Icons.person_add_rounded, size: 16),
                        label: const Text(
                          'Add Students',
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
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$totalCount ${totalCount == 1 ? "Student" : "Students"} Enrolled',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      Text(
                        '${students.length} found',
                        style: const TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: widget.classSection.students.isEmpty
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
                                    Icons.people_alt_outlined,
                                    size: 32,
                                    color: textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No students added yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Click "+ Add Students" above to add or import students.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : students.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  'No students matching "$_searchQuery".',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth >= 650) {
                                  return GridView.builder(
                                    itemCount: students.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      mainAxisExtent: 70,
                                    ),
                                    itemBuilder: (context, index) {
                                      return _buildStudentCard(students[index]);
                                    },
                                  );
                                }
                                return ListView.separated(
                                  itemCount: students.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    return _buildStudentCard(students[index]);
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

  Widget _buildStudentCard(StudentItem student) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accentColor,
              child: Text(
                student.fullName.isNotEmpty
                    ? student.fullName[0].toUpperCase()
                    : 'S',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                student.fullName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => startReadingAssessment(student),
              icon: const Icon(
                Icons.mic_rounded,
                size: 16,
              ),
              label: const Text(
                'Assess',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: textPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              tooltip: 'Remove student',
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => deleteStudent(student),
            ),
          ],
        ),
      ),
    );
  }
}
