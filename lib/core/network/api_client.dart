import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(milliseconds: AppConfig.apiTimeoutMs),
    receiveTimeout: const Duration(milliseconds: AppConfig.apiTimeoutMs),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  return dio;
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

class AuthInterceptor extends Interceptor {
  final Ref _ref;
  AuthInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try token refresh
      final storage = _ref.read(secureStorageProvider);
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
          final response = await dio.post('/auth/refresh', data: {
            'refresh_token': refreshToken,
          });
          if (response.statusCode == 200) {
            final data = response.data['data'];
            await storage.write(key: 'access_token', value: data['access_token']);
            await storage.write(key: 'refresh_token', value: data['refresh_token']);

            // Retry the failed request with the new token
            err.requestOptions.headers['Authorization'] = 'Bearer ${data['access_token']}';
            final retryResponse = await dio.fetch(err.requestOptions);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          // Refresh failed — clear tokens
          await storage.deleteAll();
        }
      }
    }
    handler.next(err);
  }
}

/// Generic API response wrapper
class ApiResponse<T> {
  final T? data;
  final ApiError? error;

  const ApiResponse._({this.data, this.error});

  bool get isSuccess => error == null;

  factory ApiResponse.success(T? data) => ApiResponse._(data: data);
  factory ApiResponse.error(ApiError err) => ApiResponse._(error: err);
}

class ApiError {
  final String message;
  final String? code;

  const ApiError({required this.message, this.code});

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
    message: json['message_fr'] ?? json['message'] ?? 'Erreur inconnue',
    code: json['code'],
  );

  factory ApiError.fromDioError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final err = data['error'];
        if (err is Map<String, dynamic>) return ApiError.fromJson(err);
        final msg = data['message_fr'] ?? data['message'];
        if (msg != null) return ApiError(message: msg.toString());
      }
      return ApiError(message: e.message ?? 'Erreur réseau');
    }
    return ApiError(message: e.toString());
  }
}
