import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/super_admin_models.dart';

final superAdminRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return SuperAdminRepository(dio: dio);
});

class SuperAdminRepository {
  final dynamic dio;

  SuperAdminRepository({required this.dio});

  /// GET /super-admin/metrics
  Future<ApiResponse<PlatformMetrics>> getMetrics() async {
    try {
      final response = await dio.get('/super-admin/metrics');
      return ApiResponse.success(PlatformMetrics.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  /// GET /super-admin/tenants
  Future<ApiResponse<List<Tenant>>> getTenants({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null) params['status'] = status;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await dio.get('/super-admin/tenants', queryParameters: params);
      final data = response.data['data'] as List? ?? [];
      final tenants = data.map((t) => Tenant.fromJson(t)).toList();
      return ApiResponse.success(tenants);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  /// POST /super-admin/tenants — Create new tenant (restaurant)
  Future<ApiResponse<TenantCreateResult>> createTenant({
    required String name,
    required String slug,
    required String adminEmail,
    String planTier = 'starter',
    String countryCode = 'DZ',
    String currencyCode = 'DZD',
    String timezone = 'Africa/Algiers',
  }) async {
    try {
      final response = await dio.post('/super-admin/tenants', data: {
        'name': name,
        'slug': slug,
        'admin_email': adminEmail,
        'plan_tier': planTier,
        'country_code': countryCode,
        'currency_code': currencyCode,
        'timezone': timezone,
      });
      return ApiResponse.success(TenantCreateResult.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  /// PATCH /super-admin/tenants/:id — Update tenant (suspend, reactivate, change plan)
  Future<ApiResponse<Tenant>> updateTenant(
    String tenantId, {
    String? status,
    String? planTier,
    int? maxBranches,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (status != null) data['status'] = status;
      if (planTier != null) data['plan_tier'] = planTier;
      if (maxBranches != null) data['max_branches'] = maxBranches;

      final response = await dio.patch('/super-admin/tenants/$tenantId', data: data);
      return ApiResponse.success(Tenant.fromJson(response.data['data']));
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  /// GET /super-admin/subscription-plans
  Future<ApiResponse<List<SubscriptionPlan>>> getPlans() async {
    try {
      final response = await dio.get('/super-admin/subscription-plans');
      final data = response.data['data'] as List? ?? [];
      final plans = data.map((p) => SubscriptionPlan.fromJson(p)).toList();
      return ApiResponse.success(plans);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }
}
