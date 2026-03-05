import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../providers/super_admin_provider.dart';
import '../../domain/super_admin_models.dart';

class TenantsManagementScreen extends ConsumerStatefulWidget {
  const TenantsManagementScreen({super.key});

  @override
  ConsumerState<TenantsManagementScreen> createState() =>
      _TenantsManagementScreenState();
}

class _TenantsManagementScreenState
    extends ConsumerState<TenantsManagementScreen> {
  final _searchController = TextEditingController();
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(superAdminProvider);
      if (state.tenants.isEmpty) {
        ref.read(superAdminProvider.notifier).loadAll();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gestion des Restaurants',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showCreateDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau Restaurant'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search & filter bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom ou slug...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(superAdminProvider.notifier)
                                    .setSearch('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) =>
                        ref.read(superAdminProvider.notifier).setSearch(v),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String?>(
                      value: _statusFilter,
                      hint: const Text('Tous les statuts'),
                      items: const [
                        DropdownMenuItem(
                            value: null,
                            child: Text('Tous les statuts')),
                        DropdownMenuItem(
                            value: 'active', child: Text('Actif')),
                        DropdownMenuItem(
                            value: 'onboarding',
                            child: Text('Onboarding')),
                        DropdownMenuItem(
                            value: 'suspended',
                            child: Text('Suspendu')),
                      ],
                      onChanged: (v) {
                        setState(() => _statusFilter = v);
                        ref
                            .read(superAdminProvider.notifier)
                            .setStatusFilter(v);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tenants list
            Expanded(
              child: state.isLoading && state.tenants.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.tenants.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_outlined,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                'Aucun restaurant trouvé',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: () => _showCreateDialog(context),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Créer un restaurant'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: state.tenants.length,
                          itemBuilder: (context, index) {
                            return _TenantCard(
                              tenant: state.tenants[index],
                              plans: state.plans,
                              onStatusChange: (status) async {
                                await ref
                                    .read(superAdminProvider.notifier)
                                    .updateTenantStatus(
                                        state.tenants[index].id, status);
                              },
                              onPlanChange: (plan) async {
                                await ref
                                    .read(superAdminProvider.notifier)
                                    .updateTenantPlan(
                                        state.tenants[index].id, plan);
                              },
                            );
                          },
                        ),
            ),

            // Error display
            if (state.error != null) ...[
              const SizedBox(height: 12),
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
                          style: const TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CreateTenantDialog(
        plans: ref.read(superAdminProvider).plans,
        onCreate: (name, slug, email, plan) async {
          final result =
              await ref.read(superAdminProvider.notifier).createTenant(
                    name: name,
                    slug: slug,
                    adminEmail: email,
                    planTier: plan,
                  );
          if (result != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Restaurant "$name" cree avec succes!\nLien d\'activation: ${result.onboardingLink}'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 8),
              ),
            );
          }
          return result != null;
        },
      ),
    );
  }
}

// ─── Tenant Card ──────────────────────────────────────
class _TenantCard extends StatelessWidget {
  final Tenant tenant;
  final List<SubscriptionPlan> plans;
  final Future<void> Function(String status) onStatusChange;
  final Future<void> Function(String plan) onPlanChange;

  const _TenantCard({
    required this.tenant,
    required this.plans,
    required this.onStatusChange,
    required this.onPlanChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Logo / avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tenant.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: tenant.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tenant.slug} • ${tenant.billingEmail}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _InfoChip(
                          icon: Icons.people_outline,
                          label: '${tenant.userCount} utilisateurs'),
                      const SizedBox(width: 12),
                      _InfoChip(
                          icon: Icons.workspace_premium_outlined,
                          label: _planLabel(tenant.planTier)),
                      const SizedBox(width: 12),
                      _InfoChip(
                          icon: Icons.store_outlined,
                          label: '${tenant.maxBranches} branche(s)'),
                      if (tenant.createdAt != null) ...[
                        const SizedBox(width: 12),
                        _InfoChip(
                            icon: Icons.calendar_today_outlined,
                            label: FormatUtils.date(tenant.createdAt!)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) => _handleAction(context, action),
              itemBuilder: (_) => [
                if (tenant.status != 'active')
                  const PopupMenuItem(
                    value: 'activate',
                    child: ListTile(
                      leading:
                          Icon(Icons.check_circle, color: AppColors.success),
                      title: Text('Activer'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                if (tenant.status != 'suspended')
                  const PopupMenuItem(
                    value: 'suspend',
                    child: ListTile(
                      leading:
                          Icon(Icons.block, color: AppColors.error),
                      title: Text('Suspendre'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                const PopupMenuDivider(),
                ...plans.map((p) => PopupMenuItem(
                      value: 'plan:${p.name}',
                      child: ListTile(
                        leading: Icon(Icons.workspace_premium,
                            color: tenant.planTier == p.name
                                ? AppColors.primary
                                : Colors.grey),
                        title: Text(
                          p.displayNameFr,
                          style: TextStyle(
                            fontWeight: tenant.planTier == p.name
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    if (action == 'activate') {
      onStatusChange('active');
    } else if (action == 'suspend') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirmer la suspension'),
          content: Text(
              'Suspendre "${tenant.name}"? Les utilisateurs ne pourront plus se connecter.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                Navigator.pop(context);
                onStatusChange('suspended');
              },
              child: const Text('Suspendre'),
            ),
          ],
        ),
      );
    } else if (action.startsWith('plan:')) {
      onPlanChange(action.substring(5));
    }
  }

  String _planLabel(String tier) {
    switch (tier) {
      case 'starter':
        return 'Starter';
      case 'pro':
        return 'Pro';
      case 'enterprise':
        return 'Enterprise';
      default:
        return tier;
    }
  }
}

// ─── Status Badge ─────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = AppColors.success;
        label = 'Actif';
        break;
      case 'suspended':
        color = AppColors.error;
        label = 'Suspendu';
        break;
      case 'onboarding':
        color = AppColors.warning;
        label = 'Onboarding';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Info Chip ────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Create Tenant Dialog ─────────────────────────────
class _CreateTenantDialog extends StatefulWidget {
  final List<SubscriptionPlan> plans;
  final Future<bool> Function(
      String name, String slug, String email, String plan) onCreate;

  const _CreateTenantDialog({required this.plans, required this.onCreate});

  @override
  State<_CreateTenantDialog> createState() => _CreateTenantDialogState();
}

class _CreateTenantDialogState extends State<_CreateTenantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedPlan = 'starter';
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau Restaurant'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du restaurant *',
                  hintText: 'Ex: Restaurant El Bahia',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Nom requis' : null,
                onChanged: (v) {
                  // Auto-generate slug
                  _slugController.text = v
                      .toLowerCase()
                      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                      .replaceAll(RegExp(r'^-|-$'), '');
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'Slug (identifiant unique) *',
                  hintText: 'ex: restaurant-el-bahia',
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (v) =>
                    (v?.isEmpty ?? true) ? 'Slug requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email du proprietaire (admin) *',
                  hintText: 'admin@restaurant.dz',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Email requis';
                  if (!v!.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPlan,
                decoration: const InputDecoration(
                  labelText: 'Plan d\'abonnement',
                  prefixIcon: Icon(Icons.workspace_premium),
                ),
                items: [
                  if (widget.plans.isEmpty) ...[
                    const DropdownMenuItem(
                        value: 'starter', child: Text('Starter')),
                    const DropdownMenuItem(
                        value: 'pro', child: Text('Professionnel')),
                    const DropdownMenuItem(
                        value: 'enterprise', child: Text('Enterprise')),
                  ] else
                    ...widget.plans.map((p) => DropdownMenuItem(
                          value: p.name,
                          child: Text(
                              '${p.displayNameFr} (${FormatUtils.money(p.monthlyPriceCents)}/mois)'),
                        )),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedPlan = v);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Un compte administrateur sera cree avec un lien d\'activation envoye par email.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Creer'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final success = await widget.onCreate(
      _nameController.text.trim(),
      _slugController.text.trim(),
      _emailController.text.trim(),
      _selectedPlan,
    );
    if (mounted) {
      setState(() => _loading = false);
      if (success) Navigator.pop(context);
    }
  }
}
