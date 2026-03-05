import '../../../core/constants/enums.dart';

class User {
  final String id;
  final String tenantId;
  final String email;
  final String? phone;
  final String firstNameFr;
  final String? firstNameAr;
  final String lastNameFr;
  final String? lastNameAr;
  final UserRole role;
  final String? roleId;
  final String? branchId;
  final String preferredLocale;
  final bool isActive;
  final List<String> permissions;

  User({
    required this.id,
    required this.tenantId,
    required this.email,
    this.phone,
    required this.firstNameFr,
    this.firstNameAr,
    required this.lastNameFr,
    this.lastNameAr,
    required this.role,
    this.roleId,
    this.branchId,
    this.preferredLocale = 'fr',
    this.isActive = true,
    this.permissions = const [],
  });

  String get displayName => '$firstNameFr $lastNameFr';
  String get displayNameAr => '${firstNameAr ?? firstNameFr} ${lastNameAr ?? lastNameFr}';

  bool hasPermission(String perm) {
    if (permissions.contains('*')) return true;
    if (permissions.contains(perm)) return true;
    // Check wildcard: orders.* matches orders.create
    final parts = perm.split('.');
    if (parts.length == 2 && permissions.contains('${parts[0]}.*')) return true;
    return false;
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] ?? '',
    tenantId: json['tenant_id'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'],
    firstNameFr: json['first_name_fr'] ?? '',
    firstNameAr: json['first_name_ar'],
    lastNameFr: json['last_name_fr'] ?? '',
    lastNameAr: json['last_name_ar'],
    role: UserRoleX.fromString(json['role'] ?? 'staff'),
    roleId: json['role_id'],
    preferredLocale: json['preferred_locale'] ?? 'fr',
    isActive: json['is_active'] == true || json['is_active'] == 1,
    branchId: json['branch_id'] ?? (json['branch'] is Map ? json['branch']['id'] : null),
    permissions: List<String>.from(json['permissions'] ?? []),
  );
}
