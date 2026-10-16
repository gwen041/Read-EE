import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reading_material.dart';
import 'api_config.dart';
import 'auth_service.dart';

class MaterialService {
  static Future<List<ReadingMaterialItem>> getMaterials({
    int? gradeLevel,
  }) async {
    String url = '${ApiConfig.baseUrl}/api/materials';
    if (gradeLevel != null) {
      url += '?gradeLevel=$gradeLevel';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: AuthService.authHeaders,
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to load reading materials.');
    }

    final rawList = data['materials'] as List<dynamic>? ?? [];
    return rawList
        .map((m) => ReadingMaterialItem.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  static Future<ReadingMaterialItem> createMaterial({
    required String title,
    required String passage,
    required int gradeLevel,
    required List<Map<String, dynamic>> questions,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/materials'),
      headers: AuthService.authHeaders,
      body: jsonEncode({
        'title': title,
        'passage': passage,
        'gradeLevel': gradeLevel,
        'questions': questions,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to create reading material.');
    }

    return ReadingMaterialItem.fromJson(
      data['material'] as Map<String, dynamic>,
    );
  }

  static Future<void> deleteMaterial(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/materials/$id'),
      headers: AuthService.authHeaders,
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] ?? 'Failed to delete reading material.');
    }
  }
}