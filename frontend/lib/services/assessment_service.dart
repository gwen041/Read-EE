import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;

import '../models/assessment.dart';
import 'api_config.dart';
import 'auth_service.dart';

class AssessmentService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> submitAssessment({
    required String audioPath,
    required String passage,
    required List<String> studentAnswers,
    int? readingMaterialId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/assessment'),
    );

    final audioBytes = await XFile(audioPath).readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'audioFile',
        audioBytes,
        filename: 'reading_recording.wav',
      ),
    );

    request.fields['expectedText'] = passage;
    request.fields['studentAnswers'] = jsonEncode(studentAnswers);
    if (readingMaterialId != null) {
      request.fields['readingMaterialId'] = readingMaterialId.toString();
    }

    final response = await request.send();

    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception(
        'Assessment failed: '
        '${response.statusCode} $responseBody',
      );
    }

    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  // Finalize assessment after teacher verification.
  static Future<Map<String, dynamic>> finalizeAssessment({
    required Map<String, dynamic> accuracy,
    required Map<String, dynamic> wpm,
    required Map<String, dynamic> comprehension,
    required Map<int, bool> decisions,
  }) async {
    final formattedDecisions = <String, bool>{};

    decisions.forEach((key, value) {
      formattedDecisions[key.toString()] = value;
    });

    final response = await http.post(
      Uri.parse('$baseUrl/api/assessment/finalize'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'accuracy': accuracy,
        'wpm': wpm,
        'comprehension': comprehension,
        'decisions': formattedDecisions,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Assessment finalization failed: '
        '${response.statusCode} ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // Fetch all saved assessments for the logged-in teacher from PostgreSQL.
  static Future<List<Assessment>> getAssessments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/assessments'),
      headers: AuthService.authHeaders,
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch assessments.');
    }

    final list = data['assessments'] as List<dynamic>;
    return list
        .map((item) => Assessment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Save a completed assessment to PostgreSQL.
  static Future<Assessment> saveAssessment({
    required int studentId,
    required int readingMaterialId,
    required double accuracy,
    required double wpm,
    required double comprehensionScore,
    required String classification,
    required Map<String, dynamic> accuracyDetails,
    required Map<String, dynamic> comprehensionDetails,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/assessments'),
      headers: AuthService.authHeaders,
      body: jsonEncode({
        'studentId': studentId,
        'readingMaterialId': readingMaterialId,
        'accuracy': accuracy,
        'wpm': wpm,
        'comprehensionScore': comprehensionScore.round(),
        'classification': classification,
        'accuracyDetails': accuracyDetails,
        'comprehensionDetails': comprehensionDetails,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Failed to save assessment.');
    }

    return Assessment.fromJson(data['assessment'] as Map<String, dynamic>);
  }

  // Update an existing assessment in PostgreSQL after teacher verification.
  static Future<Assessment> updateAssessment({
    required int assessmentId,
    required double accuracy,
    required double wpm,
    required double comprehensionScore,
    required String classification,
    required Map<String, dynamic> accuracyDetails,
    required Map<String, dynamic> comprehensionDetails,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/assessments/$assessmentId'),
      headers: AuthService.authHeaders,
      body: jsonEncode({
        'accuracy': accuracy,
        'wpm': wpm,
        'comprehensionScore': comprehensionScore.round(),
        'classification': classification,
        'accuracyDetails': accuracyDetails,
        'comprehensionDetails': comprehensionDetails,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update assessment.');
    }

    return Assessment.fromJson(data['assessment'] as Map<String, dynamic>);
  }
}