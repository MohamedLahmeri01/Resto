import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/super_admin_repository.dart';
import '../domain/super_admin_models.dart';

// ─── State ─────────────────────────────────────────────
class SuperAdminState {
  final PlatformMetrics? metrics;
  final List<Tenant> tenants;
  final List<SubscriptionPlan> plans;
  final bool isLoading;
  final String? error;
  final String? statusFilter;
  final String? searchQuery;

  const SuperAdminState({
    this.metrics,
    this.tenants = const [],
    this.plans = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.searchQuery,
  });

  SuperAdminState copyWith({
    PlatformMetrics? metrics,
    List<Tenant>? tenants,
    List<SubscriptionPlan>? plans,
    bool? isLoading,
    String? error,
    String? statusFilter,
    String? searchQuery,
  }) =>
      SuperAdminState(
        metrics: metrics ?? this.metrics,
        tenants: tenants ?? this.tenants,
        plans: plans ?? this.plans,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        statusFilter: statusFilter ?? this.statusFilter,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

// ─── Notifier ──────────────────────────────────────────
class SuperAdminNotifier extends StateNotifier<SuperAdminState> {
  final SuperAdminRepository _repo;

  SuperAdminNotifier(this._repo) : super(const SuperAdminState());

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);

    final metricsResult = await _repo.getMetrics();
    final tenantsResult = await _repo.getTenants(
      status: state.statusFilter,
      search: state.searchQuery,
    );
    final plansResult = await _repo.getPlans();

    state = state.copyWith(
      isLoading: false,
      metrics: metricsResult.isSuccess ? metricsResult.data : state.metrics,
      tenants: tenantsResult.isSuccess ? tenantsResult.data! : state.tenants,
      plans: plansResult.isSuccess ? plansResult.data! : state.plans,
      error: !metricsResult.isSuccess
          ? metricsResult.error?.message
          : !tenantsResult.isSuccess
              ? tenantsResult.error?.message
              : null,
    );
  }

  Future<void> refreshTenants() async {
    final result = await _repo.getTenants(
      status: state.statusFilter,
      search: state.searchQuery,
    );
    if (result.isSuccess) {
      state = state.copyWith(tenants: result.data!);
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
    refreshTenants();
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query.isEmpty ? null : query);
    refreshTenants();
  }

  Future<TenantCreateResult?> createTenant({
    required String name,
    required String slug,
    required String adminEmail,
    String planTier = 'starter',
  }) async {
    final result = await _repo.createTenant(
      name: name,
      slug: slug,
      adminEmail: adminEmail,
      planTier: planTier,
    );
    if (result.isSuccess) {
      await loadAll(); // Refresh everything
      return result.data;
    }
    state = state.copyWith(error: result.error?.message);
    return null;
  }

  Future<bool> updateTenantStatus(String tenantId, String newStatus) async {
    final result = await _repo.updateTenant(tenantId, status: newStatus);
    if (result.isSuccess) {
      await refreshTenants();
      // Also refresh metrics
      final metricsResult = await _repo.getMetrics();
      if (metricsResult.isSuccess) {
        state = state.copyWith(metrics: metricsResult.data);
      }
      return true;
    }
    state = state.copyWith(error: result.error?.message);
    return false;
  }

  Future<bool> updateTenantPlan(String tenantId, String planTier) async {
    final result = await _repo.updateTenant(tenantId, planTier: planTier);
    if (result.isSuccess) {
      await refreshTenants();
      return true;
    }
    state = state.copyWith(error: result.error?.message);
    return false;
  }
}

// ─── Providers ─────────────────────────────────────────
final superAdminProvider =
    StateNotifierProvider<SuperAdminNotifier, SuperAdminState>((ref) {
  final repo = ref.watch(superAdminRepositoryProvider);
  return SuperAdminNotifier(repo);
});

final platformMetricsProvider = Provider<PlatformMetrics?>((ref) {
  return ref.watch(superAdminProvider).metrics;
});

final tenantListProvider = Provider<List<Tenant>>((ref) {
  return ref.watch(superAdminProvider).tenants;
});
