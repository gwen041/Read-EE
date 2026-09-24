class ClassSection {
  final String gradeLevel;
  final String sectionName;
  final List<String> students;

  ClassSection({
    required this.gradeLevel,
    required this.sectionName,
    List<String>? students,
  }) : students = students ?? [];
}