import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/class_section.dart';
import 'api_config.dart';
import 'auth_service.dart';

class ClassService {
  static Future<List<ClassSection>> getClasses() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/classes'),
      headers: AuthService.authHeaders,
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to load classes.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawList = data['classes'] as List<dynamic>? ?? [];
    return rawList
        .map((c) => ClassSection.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  static Future<ClassSection> createSection({
    required String gradeLevel,
    required String sectionName,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/classes'),
      headers: AuthService.authHeaders,
      body: jsonEncode({
        'gradeLevel': gradeLevel,
        'sectionName': sectionName,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to create section.');
    }

    return ClassSection.fromJson(data['classSection'] as Map<String, dynamic>);
  }

  static Future<List<ClassSection>> createSectionsBatch(
    List<Map<String, String>> sections,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/classes/batch'),
      headers: AuthService.authHeaders,
      body: jsonEncode({'sections': sections}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to save sections.');
    }

    final rawList = data['sections'] as List<dynamic>? ?? [];
    return rawList
        .map((c) => ClassSection.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  static Future<StudentItem> addStudent({
    required int classId,
    required String fullName,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/classes/$classId/students'),
      headers: AuthService.authHeaders,
      body: jsonEncode({'fullName': fullName}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to add student.');
    }

    return StudentItem.fromJson(data['student'] as Map<String, dynamic>);
  }

  static Future<List<StudentItem>> importStudents({
    required int classId,
    required List<String> studentNames,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/classes/$classId/students/import'),
      headers: AuthService.authHeaders,
      body: jsonEncode({'studentNames': studentNames}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to import students.');
    }

    final rawList = data['students'] as List<dynamic>? ?? [];
    return rawList
        .map((s) => StudentItem.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  static Future<void> deleteStudent({
    required int classId,
    required int studentId,
  }) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/classes/$classId/students/$studentId'),
      headers: AuthService.authHeaders,
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete student.');
    }
  }
}