import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/order_model.dart';

final orderRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return OrderRepository(dio: dio);
});

class OrderRepository {
  final dynamic dio;
  OrderRepository({required this.dio});

  Future<ApiResponse<Order>> createOrder(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/orders', data: data);
      return ApiResponse.success(Order.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<List<Order>>> getOrders({
    String? status,
    String? orderType,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (status != null) params['status'] = status;
      if (orderType != null) params['order_type'] = orderType;
      final response = await dio.get('/orders', queryParameters: params);
      final list = (response.data['data'] as List<dynamic>)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(list);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<Order>> getOrder(String id) async {
    try {
      final response = await dio.get('/orders/$id');
      return ApiResponse.success(Order.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<Order>> addItems(String orderId, List<Map<String, dynamic>> items) async {
    try {
      final response = await dio.post('/orders/$orderId/items', data: {'items': items});
      return ApiResponse.success(Order.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<void>> updateStatus(String orderId, String status) async {
    try {
      await dio.patch('/orders/$orderId/status', data: {'status': status});
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<void>> voidOrder(String orderId, String reason) async {
    try {
      await dio.post('/orders/$orderId/void', data: {'reason': reason});
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<void>> fireCourse(String orderId, int courseNumber) async {
    try {
      await dio.post('/orders/$orderId/fire', data: {'course_number': courseNumber});
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> processPayment(String orderId, Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/payments/$orderId/pay', data: data);
      return ApiResponse.success(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }
}
