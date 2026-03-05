import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/table_model.dart';

final tableRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return TableRepository(dio: dio);
});

class TableRepository {
  final dynamic dio;
  TableRepository({required this.dio});

  Future<ApiResponse<Map<String, dynamic>>> getTablesWithSections() async {
    try {
      final response = await dio.get('/tables');
      return ApiResponse.success(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<RestaurantTable>> updateStatus(String id, String status) async {
    try {
      final response = await dio.patch('/tables/$id/status', data: {'status': status});
      return ApiResponse.success(RestaurantTable.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<RestaurantTable>> createTable(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/tables', data: data);
      return ApiResponse.success(RestaurantTable.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<RestaurantTable>> updateTable(String id, Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/tables/$id', data: data);
      return ApiResponse.success(RestaurantTable.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<void>> deleteTable(String id) async {
    try {
      await dio.delete('/tables/$id');
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }
}
