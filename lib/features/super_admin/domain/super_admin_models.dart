/// Super Admin data models
class Tenant {
  final String id;
  final String name;
  final String slug;
  final String status;
  final String planTier;
  final String billingEmail;
  final String? phone;
  final String? address;
  final String? logoUrl;
  final String countryCode;
  final String currencyCode;
  final String timezone;
  final int maxBranches;
  final int userCount;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final DateTime? createdAt;

  Tenant({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.planTier,
    required this.billingEmail,
    this.phone,
    this.address,
    this.logoUrl,
    this.countryCode = 'DZ',
    this.currencyCode = 'DZD',
    this.timezone = 'Africa/Algiers',
    this.maxBranches = 1,
    this.userCount = 0,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.createdAt,
  });

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isOnboarding => status == 'onboarding';

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        status: json['status'] ?? 'onboarding',
        planTier: json['plan_tier'] ?? 'starter',
        billingEmail: json['billing_email'] ?? '',
        phone: json['phone'],
        address: json['address'],
        logoUrl: json['logo_url'],
        countryCode: json['country_code'] ?? 'DZ',
        currencyCode: json['currency_code'] ?? 'DZD',
        timezone: json['timezone'] ?? 'Africa/Algiers',
        maxBranches: json['max_branches'] ?? 1,
        userCount: json['user_count'] ?? 0,
        subscriptionStart: json['subscription_start'] != null
            ? DateTime.tryParse(json['subscription_start'].toString())
            : null,
        subscriptionEnd: json['subscription_end'] != null
            ? DateTime.tryParse(json['subscription_end'].toString())
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );
}

class PlatformMetrics {
  final int totalTenants;
  final int activeTenants;
  final int totalUsers;
  final int todayOrders;
  final List<PlanBreakdown> planBreakdown;

  PlatformMetrics({
    required this.totalTenants,
    required this.activeTenants,
    required this.totalUsers,
    required this.todayOrders,
    required this.planBreakdown,
  });

  factory PlatformMetrics.fromJson(Map<String, dynamic> json) => PlatformMetrics(
        totalTenants: _toInt(json['total_tenants']),
        activeTenants: _toInt(json['active_tenants']),
        totalUsers: _toInt(json['total_users']),
        todayOrders: _toInt(json['today_orders']),
        planBreakdown: (json['plan_breakdown'] as List? ?? [])
            .map((e) => PlanBreakdown.fromJson(e))
            .toList(),
      );

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class PlanBreakdown {
  final String planTier;
  final int count;

  PlanBreakdown({required this.planTier, required this.count});

  factory PlanBreakdown.fromJson(Map<String, dynamic> json) => PlanBreakdown(
        planTier: json['plan_tier'] ?? 'unknown',
        count: json['count'] is int
            ? json['count']
            : int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      );
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String displayNameFr;
  final String? displayNameAr;
  final int monthlyPriceCents;
  final int maxBranches;
  final int maxUsers;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.displayNameFr,
    this.displayNameAr,
    required this.monthlyPriceCents,
    required this.maxBranches,
    required this.maxUsers,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => SubscriptionPlan(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        displayNameFr: json['display_name_fr'] ?? json['name'] ?? '',
        displayNameAr: json['display_name_ar'],
        monthlyPriceCents: json['monthly_price_cents'] ?? 0,
        maxBranches: json['max_branches'] ?? 1,
        maxUsers: json['max_users'] ?? 5,
        features: json['features_json'] is String
            ? List<String>.from(_tryParseJson(json['features_json']))
            : json['features_json'] is List
                ? List<String>.from(json['features_json'])
                : <String>[],
      );

  static dynamic _tryParseJson(String s) {
    try {
      return (s.startsWith('[')) ? _simpleParseList(s) : <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  static List<String> _simpleParseList(String s) {
    // Simple JSON array parse
    final trimmed = s.substring(1, s.length - 1);
    if (trimmed.isEmpty) return [];
    return trimmed.split(',').map((e) => e.trim().replaceAll('"', '').replaceAll("'", '')).toList();
  }
}

class TenantCreateResult {
  final String tenantId;
  final String adminUserId;
  final String onboardingLink;
  final String status;

  TenantCreateResult({
    required this.tenantId,
    required this.adminUserId,
    required this.onboardingLink,
    required this.status,
  });

  factory TenantCreateResult.fromJson(Map<String, dynamic> json) => TenantCreateResult(
        tenantId: json['tenant_id'] ?? '',
        adminUserId: json['admin_user_id'] ?? '',
        onboardingLink: json['onboarding_link'] ?? '',
        status: json['status'] ?? 'onboarding',
      );
}
