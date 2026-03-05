import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'package:resto/features/auth/domain/user_model.dart';
import 'package:resto/core/constants/enums.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _Sidebar(
            user: user,
            currentPath: location,
            onNavigate: (path) => context.go(path),
            onLogout: () => ref.read(authProvider.notifier).logout(),
          ),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final User? user;
  final String currentPath;
  final void Function(String) onNavigate;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.user,
    required this.currentPath,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final items = _getMenuItems();

    return Container(
      width: 240,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // Brand header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Resto RMS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: items.map((item) => _NavItem(
                icon: item.icon,
                label: item.label,
                path: item.path,
                isActive: currentPath == item.path,
                onTap: () => onNavigate(item.path),
              )).toList(),
            ),
          ),

          // User info + logout
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  child: Text(
                    user != null ? '${user!.firstNameFr[0]}${user!.lastNameFr[0]}'.toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.role.name ?? '',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white54, size: 20),
                  onPressed: onLogout,
                  tooltip: 'Déconnexion',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_MenuItem> _getMenuItems() {
    final role = user?.role ?? UserRole.staff;

    // ─── Super Admin menu ─────────────────────────
    if (role == UserRole.superAdmin) {
      return const [
        _MenuItem(Icons.dashboard, 'Tableau de bord', '/admin'),
        _MenuItem(Icons.store, 'Restaurants', '/admin/tenants'),
        _MenuItem(Icons.workspace_premium, 'Plans', '/admin/plans'),
        _MenuItem(Icons.settings, 'Parametres', '/admin/settings'),
      ];
    }

    // ─── Restaurant staff menu ────────────────────
    final items = <_MenuItem>[
      const _MenuItem(Icons.dashboard, 'Tableau de bord', '/'),
      const _MenuItem(Icons.point_of_sale, 'POS / Caisse', '/pos'),
    ];

    // KDS - for kitchen roles and managers
    if ([UserRole.chef, UserRole.manager, UserRole.owner, UserRole.superAdmin].contains(role)) {
      items.add(const _MenuItem(Icons.kitchen, 'Cuisine (KDS)', '/kds'));
    }

    items.add(const _MenuItem(Icons.table_restaurant, 'Tables', '/tables'));

    // Management screens
    if ([UserRole.manager, UserRole.owner, UserRole.superAdmin].contains(role)) {
      items.addAll([
        const _MenuItem(Icons.menu_book, 'Menu', '/menu'),
        const _MenuItem(Icons.inventory_2, 'Inventaire', '/inventory'),
        const _MenuItem(Icons.people, 'Personnel', '/staff'),
      ]);
    }

    items.add(const _MenuItem(Icons.settings, 'Paramètres', '/settings'));
    return items;
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String path;
  const _MenuItem(this.icon, this.label, this.path);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isActive ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: isActive ? AppColors.primary : Colors.white54),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white70,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
