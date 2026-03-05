import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../providers/super_admin_provider.dart';
import '../../domain/super_admin_models.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(superAdminProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: state.isLoading && state.metrics == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(superAdminProvider.notifier).loadAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plateforme Admin',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gestion des restaurants et abonnements',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () =>
                              ref.read(superAdminProvider.notifier).loadAll(),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Actualiser'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Metrics cards
                    if (state.metrics != null)
                      _buildMetricsGrid(state.metrics!),
                    const SizedBox(height: 24),

                    // Plan breakdown
                    if (state.metrics != null &&
                        state.metrics!.planBreakdown.isNotEmpty)
                      _buildPlanBreakdown(state.metrics!.planBreakdown),
                    const SizedBox(height: 24),

                    if (state.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(state.error!,
                                  style:
                                      const TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsGrid(PlatformMetrics m) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth > 800 ? 4 : constraints.maxWidth > 500 ? 2 : 1;
        final items = [
          _MetricCard(
            title: 'Restaurants',
            value: '${m.totalTenants}',
            icon: Icons.store,
            color: AppColors.primary,
          ),
          _MetricCard(
            title: 'Actifs',
            value: '${m.activeTenants}',
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
          _MetricCard(
            title: 'Utilisateurs',
            value: '${m.totalUsers}',
            icon: Icons.people,
            color: AppColors.accent,
          ),
          _MetricCard(
            title: 'Commandes (Aujourd\'hui)',
            value: '${m.todayOrders}',
            icon: Icons.receipt_long,
            color: Colors.deepPurple,
          ),
        ];

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: items,
        );
      },
    );
  }

  Widget _buildPlanBreakdown(List<PlanBreakdown> breakdown) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition par plan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...breakdown.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _planColor(b.planTier),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _planLabel(b.planTier),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        '${b.count}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Color _planColor(String tier) {
    switch (tier) {
      case 'starter':
        return Colors.blue;
      case 'pro':
        return AppColors.accent;
      case 'enterprise':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  String _planLabel(String tier) {
    switch (tier) {
      case 'starter':
        return 'Starter';
      case 'pro':
        return 'Professionnel';
      case 'enterprise':
        return 'Enterprise';
      default:
        return tier;
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
