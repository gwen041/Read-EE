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

    final responseBody =
        await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception(
        'Assessment failed: '
        '${response.statusCode} $responseBody',
      );
    }

    return jsonDecode(responseBody)
        as Map<String, dynamic>;
  }


  // Finalize assessment after teacher verification.
  static Future<Map<String, dynamic>> finalizeAssessment({
    required Map<String, dynamic> accuracy,
    required Map<String, dynamic> wpm,
    required Map<String, dynamic> comprehension,
    required Map<int, bool> decisions,
  }) async {

    // Convert integer keys to strings because
    // the backend/Python uses "0", "1", "2", etc.
    final formattedDecisions = <String, bool>{};

    decisions.forEach((key, value) {
      formattedDecisions[key.toString()] = value;
    });

    final response = await http.post(
      Uri.parse(
        '$baseUrl/api/assessment/finalize',
      ),
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

    return jsonDecode(response.body)
        as Map<String, dynamic>;
  }
}