import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/enums.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/pin_login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/kds/presentation/screens/kds_screen.dart';
import '../../features/menu/presentation/screens/menu_management_screen.dart';
import '../../features/pos/presentation/screens/pos_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/staff/presentation/screens/staff_screen.dart';
import '../../features/tables/presentation/screens/tables_screen.dart';
import '../../features/super_admin/presentation/screens/super_admin_dashboard_screen.dart';
import '../../features/super_admin/presentation/screens/tenants_management_screen.dart';
import '../../features/super_admin/presentation/screens/plans_management_screen.dart';
import '../shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/login/pin';

      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) {
        // Redirect super admin to their dashboard
        if (authState.user?.role == UserRole.superAdmin) return '/admin';
        return '/';
      }
      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'pin',
            builder: (_, __) => const PinLoginScreen(),
          ),
        ],
      ),

      // ─── Super Admin portal ─────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (_, __) => const SuperAdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/tenants',
            builder: (_, __) => const TenantsManagementScreen(),
          ),
          GoRoute(
            path: '/admin/plans',
            builder: (_, __) => const PlansManagementScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),

      // ─── Restaurant management app ──────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/pos',
            builder: (_, __) => const PosScreen(),
          ),
          GoRoute(
            path: '/kds',
            builder: (_, __) => const KdsScreen(),
          ),
          GoRoute(
            path: '/tables',
            builder: (_, __) => const TablesScreen(),
          ),
          GoRoute(
            path: '/menu',
            builder: (_, __) => const MenuManagementScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (_, __) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/staff',
            builder: (_, __) => const StaffScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
