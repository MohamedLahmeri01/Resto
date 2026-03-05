import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(dio: dio, storage: storage);
});

class AuthRepository {
  final dynamic dio;
  final FlutterSecureStorage storage;

  AuthRepository({required this.dio, required this.storage});

  // Token management
  Future<void> saveTokens(String access, String? refresh) async {
    await storage.write(key: 'access_token', value: access);
    if (refresh != null) {
      await storage.write(key: 'refresh_token', value: refresh);
    }
  }

  Future<String?> get accessToken => storage.read(key: 'access_token');
  Future<String?> get refreshToken => storage.read(key: 'refresh_token');

  Future<void> clearTokens() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }

  Future<void> saveTenantId(String tenantId) async {
    await storage.write(key: 'tenant_id', value: tenantId);
  }

  Future<String?> get tenantId => storage.read(key: 'tenant_id');

  // Auth API calls
  Future<ApiResponse<LoginResult>> login(String email, String password) async {
    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data['data'];
      final result = LoginResult(
        user: User.fromJson(data['user']),
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );
      await saveTokens(result.accessToken, result.refreshToken);
      await saveTenantId(result.user.tenantId);
      return ApiResponse.success(result);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<LoginResult>> loginPin(String pin, String tenantId) async {
    try {
      final response = await dio.post('/auth/login-pin', data: {
        'pin': pin,
        'tenant_id': tenantId,
      });
      final data = response.data['data'];
      final result = LoginResult(
        user: User.fromJson(data['user']),
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );
      await saveTokens(result.accessToken, result.refreshToken);
      return ApiResponse.success(result);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<User>> getMe() async {
    try {
      final response = await dio.get('/auth/me');
      return ApiResponse.success(User.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<void>> logout() async {
    try {
      final rt = await refreshToken;
      if (rt != null) {
        await dio.post('/auth/logout', data: {'refresh_token': rt});
      }
    } catch (_) {}
    await clearTokens();
    return ApiResponse.success(null);
  }

  Future<ApiResponse<LoginResult>> refresh() async {
    try {
      final rt = await refreshToken;
      if (rt == null) return ApiResponse.error(const ApiError(message: 'No refresh token'));
      final response = await dio.post('/auth/refresh', data: {'refresh_token': rt});
      final data = response.data['data'];
      final result = LoginResult(
        user: User.fromJson(data['user']),
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );
      await saveTokens(result.accessToken, result.refreshToken);
      return ApiResponse.success(result);
    } catch (e) {
      await clearTokens();
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<void>> changePassword(String current, String newPwd) async {
    try {
      await dio.post('/auth/change-password', data: {
        'current_password': current,
        'new_password': newPwd,
      });
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }
}

class LoginResult {
  final User user;
  final String accessToken;
  final String? refreshToken;

  LoginResult({
    required this.user,
    required this.accessToken,
    this.refreshToken,
  });
}
