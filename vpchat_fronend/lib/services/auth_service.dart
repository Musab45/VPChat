import '../models/auth_response.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<AuthResponse> login(String username, String password) async {
    return await _apiService.login(username, password);
  }

  Future<User> register(String username, String password) async {
    return await _apiService.register(username, password);
  }

  Future<void> saveAuthData(AuthResponse authResponse) async {
    await _storageService.saveToken(authResponse.token);
    await _storageService.saveUserInfo(
      authResponse.user.id,
      authResponse.user.username,
    );
  }

  Future<void> logout() async {
    await _storageService.clearAll();
  }

  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }

  Future<String?> getToken() async {
    return await _storageService.getToken();
  }

  Future<int?> getUserId() async {
    return await _storageService.getUserId();
  }

  Future<String?> getUsername() async {
    return await _storageService.getUsername();
  }
}
