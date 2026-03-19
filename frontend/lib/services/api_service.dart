import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal();

  String get baseUrl => apiBaseUrl;

  Map<String, String> _headers({String? token, bool jsonContent = true}) {
    final headers = <String, String>{};
    if (jsonContent) headers['Content-Type'] = 'application/json';
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      headers['X-Auth-Token'] = token;
    }
    return headers;
  }

  /// Append token as query param for GET - works around CORS blocking headers on Flutter web
  String _urlWithToken(String path, String token) {
    final uri = Uri.parse('$baseUrl$path');
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'token': token,
    }).toString();
  }

  Future<Map<String, dynamic>?> getHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/login'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> signup({
    required String email,
    required String password,
    int? age,
    double? height,
    double? weight,
    String goal = 'general',
  }) async {
    try {
      final body = jsonEncode({
        'email': email,
        'password': password,
        if (age != null) 'age': age,
        if (height != null) 'height': height,
        if (weight != null) 'weight': weight,
        'goal': goal,
      });
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/signup'),
            headers: _headers(),
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMe(String token) async {
    final (user, _) = await getMeWithError(token);
    return user;
  }

  /// Returns (userData, errorMessage). Use for debugging login/session issues.
  Future<(Map<String, dynamic>?, String?)> getMeWithError(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(_urlWithToken('/api/me', token)),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as Map<String, dynamic>, null);
      }
      return (null, '${response.statusCode}: ${response.body}');
    } catch (e) {
      return (null, e.toString());
    }
  }

  // --- Workouts ---
  Future<Map<String, dynamic>?> getTodayWorkout(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(_urlWithToken('/api/workout/today', token)),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Returns (workoutData, errorMessage). Use for debugging.
  Future<(Map<String, dynamic>?, String?)> getTodayWorkoutWithError(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(_urlWithToken('/api/workout/today', token)),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as Map<String, dynamic>, null);
      }
      return (null, '${response.statusCode}: ${response.body.length > 100 ? response.body.substring(0, 100) + "..." : response.body}');
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<Map<String, dynamic>?> completeWorkout(
    String token, {
    required List<Map<String, dynamic>> exercises,
  }) async {
    try {
      final body = jsonEncode({'exercises': exercises});
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/workout/complete'),
            headers: _headers(token: token),
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>?> getWorkoutHistory(String token, {int limit = 30}) async {
    try {
      final response = await http
          .get(
            Uri.parse(_urlWithToken('/api/workout/history?limit=$limit', token)),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getWorkoutStats(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(_urlWithToken('/api/workout/stats', token)),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // --- Health OCR ---
  Future<Map<String, dynamic>?> uploadHealthOcr(String token, XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = file.name.isNotEmpty ? file.name : 'health_report.jpg';
      final uri = Uri.parse('$baseUrl/api/health/ocr').replace(
        queryParameters: {'token': token},
      );
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-Auth-Token'] = token;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ));
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns (result, errorMessage) for Health OCR debugging.
  Future<(Map<String, dynamic>?, String?)> uploadHealthOcrWithError(String token, XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final filename = file.name.isNotEmpty ? file.name : 'health_report.jpg';
      final uri = Uri.parse('$baseUrl/api/health/ocr').replace(
        queryParameters: {'token': token},
      );
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['X-Auth-Token'] = token;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ));
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as Map<String, dynamic>, null);
      }
      String errMsg = '${response.statusCode}';
      try {
        final err = jsonDecode(response.body);
        if (err is Map && err['detail'] != null) {
          errMsg = err['detail'] is String
              ? err['detail']
              : err['detail'].toString();
        } else {
          errMsg = response.body.length > 200
              ? '${response.body.substring(0, 200)}...'
              : response.body;
        }
      } catch (_) {
        errMsg = response.body;
      }
      return (null, errMsg);
    } catch (e) {
      return (null, e.toString());
    }
  }

  // --- Social / Leaderboard ---
  Future<Map<String, dynamic>?> getLeaderboard(String token, {int? groupId}) async {
    try {
      var path = '/api/leaderboard?limit=20';
      if (groupId != null) path += '&group_id=$groupId';
      final response = await http
          .get(
            Uri.parse(_urlWithToken(path, token)),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getGroups(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(_urlWithToken('/api/groups', token)),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createGroup(String token, String name) async {
    try {
      final body = jsonEncode({'name': name});
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/groups'),
            headers: _headers(token: token),
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> joinGroup(String token, int groupId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/groups/$groupId/join'),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // --- Admin ---
  Future<List<dynamic>?> adminListUsers(String token, {String? search}) async {
    try {
      var path = '/api/admin/users?limit=100';
      if (search != null && search.isNotEmpty) path += '&search=${Uri.encodeComponent(search)}';
      final response = await http
          .get(Uri.parse(_urlWithToken(path, token)), headers: _headers(token: token))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> adminCreateUser(
    String token, {
    required String email,
    required String password,
    int? age,
    double? height,
    double? weight,
    String goal = 'general',
    String role = 'user',
  }) async {
    try {
      final body = jsonEncode({
        'email': email,
        'password': password,
        if (age != null) 'age': age,
        if (height != null) 'height': height,
        if (weight != null) 'weight': weight,
        'goal': goal,
        'role': role,
      });
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/admin/users'),
            headers: _headers(token: token),
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> adminUpdateUser(
    String token,
    int userId, {
    String? email,
    String? password,
    int? age,
    double? height,
    double? weight,
    String? goal,
    String? role,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (email != null) data['email'] = email;
      if (password != null && password.isNotEmpty) data['password'] = password;
      if (age != null) data['age'] = age;
      if (height != null) data['height'] = height;
      if (weight != null) data['weight'] = weight;
      if (goal != null) data['goal'] = goal;
      if (role != null) data['role'] = role;
      final response = await http
          .patch(
            Uri.parse('$baseUrl/api/admin/users/$userId'),
            headers: _headers(token: token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> adminDeleteUser(String token, int userId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/admin/users/$userId'),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> adminStats(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(_urlWithToken('/api/admin/stats', token)),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
