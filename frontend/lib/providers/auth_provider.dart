import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _lastError;

  static const _keyToken = 'aigymbuddy_token';

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  String? get lastError => _lastError;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  AuthProvider() {
    _loadStoredToken();
  }

  Future<void> _loadStoredToken() async {
    try {
      await _doLoadStoredToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
    } catch (_) {
      _token = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _doLoadStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    if (_token != null) {
      _user = await ApiService().getMe(_token!).timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      if (_user == null) _token = null;
    }
  }

  Future<bool> login(String email, String password) async {
    _lastError = null;
    final result = await ApiService().login(email, password);
    if (result == null || result['access_token'] == null) {
      _lastError = 'Invalid email or password. Please try again.';
      notifyListeners();
      return false;
    }
    {
      _token = result['access_token'] as String;
      final (user, err) = await ApiService().getMeWithError(_token!);
      if (user == null) {
        _token = null;
        _lastError = err != null && err.startsWith('401')
            ? 'Session expired. Please try again.'
            : 'Unable to connect. Please check your connection and try again.';
        notifyListeners();
        return false;
      }
      _user = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, _token!);
      notifyListeners();
      return true;
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    int? age,
    double? height,
    double? weight,
    String goal = 'general',
  }) async {
    final result = await ApiService().signup(
      email: email,
      password: password,
      age: age,
      height: height,
      weight: weight,
      goal: goal,
    );
    if (result != null && result['id'] != null) {
      return await login(email, password);
    }
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    notifyListeners();
  }
}
