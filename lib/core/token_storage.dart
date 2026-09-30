import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'access_token';

  String? read() => _prefs.getString(_key);
  Future<void> save(String token) => _prefs.setString(_key, token);
  Future<void> clear() => _prefs.remove(_key);
}
