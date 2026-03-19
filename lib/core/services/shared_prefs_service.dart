import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  final SharedPreferences prefs;

  SharedPrefsService(this.prefs);

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _usernameKey = 'username';
  static const String _nameKey = 'name';
  static const String _planKey = 'plan';

  Future<bool> saveToken(String token) async {
    return await prefs.setString(_tokenKey, token);
  }

  String? getToken() {
    return prefs.getString(_tokenKey);
  }

  Future<bool> removeToken() async {
    return await prefs.remove(_tokenKey);
  }

  Future<void> saveUserData({
    required String id,
    required String email,
    required String username,
    required String name,
    required String plan,
  }) async {
    await prefs.setString(_userIdKey, id);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_planKey, plan);
  }

  Map<String, String?> getUserData() {
    return {
      'id': prefs.getString(_userIdKey),
      'email': prefs.getString(_userEmailKey),
      'username': prefs.getString(_usernameKey),
      'name': prefs.getString(_nameKey),
      'plan': prefs.getString(_planKey),
    };
  }

  Future<void> clearUserData() async {
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_planKey);
  }
}
