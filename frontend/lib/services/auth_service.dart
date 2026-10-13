import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'api_config.dart';

class AuthService {
  static String? token;
  static Map<String, dynamic>? currentTeacher;

  static const String _tokenKey = 'read_ee_token';
  static const String _teacherKey = 'read_ee_teacher';

  static void init() {
    try {
      token = html.window.localStorage[_tokenKey];
      final teacherJson = html.window.localStorage[_teacherKey];
      if (teacherJson != null) {
        currentTeacher = jsonDecode(teacherJson) as Map<String, dynamic>;
      }
    } catch (_) {}
  }

  static void _saveSession(String userToken, Map<String, dynamic> teacher) {
    token = userToken;
    currentTeacher = teacher;
    try {
      html.window.localStorage[_tokenKey] = userToken;
      html.window.localStorage[_teacherKey] = jsonEncode(teacher);
    } catch (_) {}
  }

  static void logout() {
    token = null;
    currentTeacher = null;
    try {
      html.window.localStorage.remove(_tokenKey);
      html.window.localStorage.remove(_teacherKey);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Registration failed.');
    }

    _saveSession(data['token'] as String, data['teacher'] as Map<String, dynamic>);
    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Login failed.');
    }

    _saveSession(data['token'] as String, data['teacher'] as Map<String, dynamic>);
    return data;
  }

  static Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
}