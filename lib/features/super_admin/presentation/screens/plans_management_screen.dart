import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../providers/super_admin_provider.dart';
import '../../domain/super_admin_models.dart';

class PlansManagementScreen extends ConsumerStatefulWidget {
  const PlansManagementScreen({super.key});

  @override
  ConsumerState<PlansManagementScreen> createState() =>
      _PlansManagementScreenState();
}

class _PlansManagementScreenState
    extends ConsumerState<PlansManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(superAdminProvider);
      if (state.plans.isEmpty) {
        ref.read(superAdminProvider.notifier).loadAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(superAdminProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plans d\'abonnement',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Gerez les forfaits disponibles pour vos restaurants',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: state.isLoading && state.plans.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.plans.isEmpty
                      ? const Center(
                          child: Text('Aucun plan configure',
                              style: TextStyle(
                                  color: AppColors.textSecondary)))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 900
                                ? 3
                                : constraints.maxWidth > 500
                                    ? 2
                                    : 1;
                            return GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: state.plans.length,
                              itemBuilder: (context, index) {
                                return _PlanCard(plan: state.plans[index]);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final isPro = plan.name == 'pro';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPro
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan name + badge
            Row(
              children: [
                Icon(
                  _planIcon(plan.name),
                  color: _planColor(plan.name),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  plan.displayNameFr,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (isPro) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Populaire',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FormatUtils.money(plan.monthlyPriceCents),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/ mois',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Features
            _FeatureRow(
                icon: Icons.store,
                label: '${plan.maxBranches} branche(s)'),
            _FeatureRow(
                icon: Icons.people,
                label: '${plan.maxUsers} utilisateurs'),
            const SizedBox(height: 8),
            ...plan.features.take(5).map((f) => _FeatureRow(
                  icon: Icons.check_circle_outline,
                  label: _featureLabel(f),
                )),
            if (plan.features.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${plan.features.length - 5} autres...',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _planIcon(String name) {
    switch (name) {
      case 'starter':
        return Icons.rocket_launch;
      case 'pro':
        return Icons.star;
      case 'enterprise':
        return Icons.business;
      default:
        return Icons.workspace_premium;
    }
  }

  Color _planColor(String name) {
    switch (name) {
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

  String _featureLabel(String feature) {
    switch (feature) {
      case '*':
        return 'Toutes les fonctionnalites';
      case 'pos':
        return 'Point de vente (POS)';
      case 'orders':
        return 'Gestion commandes';
      case 'menu':
        return 'Gestion menu';
      case 'tables':
        return 'Gestion des tables';
      case 'inventory':
        return 'Inventaire';
      case 'staff':
        return 'Gestion personnel';
      case 'reports':
        return 'Rapports & analytiques';
      case 'crm':
        return 'CRM & fidelite';
      case 'kds':
        return 'Ecran cuisine (KDS)';
      case 'notifications':
        return 'Notifications';
      default:
        return feature;
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
