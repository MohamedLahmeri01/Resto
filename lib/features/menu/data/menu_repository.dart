import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/menu_models.dart';

final menuRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return MenuRepository(dio: dio);
});

class MenuRepository {
  final dynamic dio;
  MenuRepository({required this.dio});

  Future<ApiResponse<List<MenuCategory>>> getMenuTree() async {
    try {
      final response = await dio.get('/menu/tree');
      final list = (response.data['data'] as List<dynamic>)
          .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(list);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<List<MenuCategory>>> getCategories() async {
    try {
      final response = await dio.get('/menu/categories');
      final list = (response.data['data'] as List<dynamic>)
          .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(list);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<MenuCategory>> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/menu/categories', data: data);
      return ApiResponse.success(MenuCategory.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<MenuCategory>> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/menu/categories/$id', data: data);
      return ApiResponse.success(MenuCategory.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<void>> deleteCategory(String id) async {
    try {
      await dio.delete('/menu/categories/$id');
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<MenuItem>> createItem(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/menu/items', data: data);
      return ApiResponse.success(MenuItem.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<MenuItem>> updateItem(String id, Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/menu/items/$id', data: data);
      return ApiResponse.success(MenuItem.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<void>> deleteItem(String id) async {
    try {
      await dio.delete('/menu/items/$id');
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<void>> toggle86(String id, bool is86d) async {
    try {
      await dio.patch('/menu/items/$id/86', data: {'is_86d': is86d});
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }
}
