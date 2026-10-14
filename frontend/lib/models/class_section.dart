class StudentItem {
  final int id;
  final String fullName;

  StudentItem({
    required this.id,
    required this.fullName,
  });

  factory StudentItem.fromJson(Map<String, dynamic> json) {
    return StudentItem(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
  };

  @override
  String toString() => fullName;
}

class ClassSection {
  final int? id;
  final String gradeLevel;
  final String sectionName;
  final List<StudentItem> students;

  ClassSection({
    this.id,
    required this.gradeLevel,
    required this.sectionName,
    List<StudentItem>? students,
  }) : students = students ?? [];

  factory ClassSection.fromJson(Map<String, dynamic> json) {
    final rawStudents = json['students'] as List<dynamic>? ?? [];
    return ClassSection(
      id: json['id'] as int?,
      gradeLevel: json['gradeLevel'] is int
          ? 'Grade ${json['gradeLevel']}'
          : json['gradeLevel'].toString(),
      sectionName: json['sectionName'] as String,
      students: rawStudents
          .map((s) => StudentItem.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}