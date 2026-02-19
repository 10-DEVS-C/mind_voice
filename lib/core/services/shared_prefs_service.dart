import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  final SharedPreferences prefs;

  SharedPrefsService(this.prefs);

  static const String _tokenKey = 'auth_token';

  Future<bool> saveToken(String token) async {
    return await prefs.setString(_tokenKey, token);
  }

  String? getToken() {
    return prefs.getString(_tokenKey);
  }

  Future<bool> removeToken() async {
    return await prefs.remove(_tokenKey);
  }
}
