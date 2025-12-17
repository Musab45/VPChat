import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';

  // Save JWT token (secure)
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  // Get JWT token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // Save user info
  Future<void> saveUserInfo(int userId, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
  }

  // Get user ID
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Get username
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
