import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;

class AssessmentService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<Map<String, dynamic>> submitAssessment({
    required String audioPath,
    required String passage,
    required List<String> studentAnswers,
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

    final response = await request.send();

    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception(
        'Assessment failed: ${response.statusCode} $responseBody',
      );
    }

    return jsonDecode(responseBody) as Map<String, dynamic>;
  }
}