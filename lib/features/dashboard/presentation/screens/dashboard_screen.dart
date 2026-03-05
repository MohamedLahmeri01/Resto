import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Map<String, dynamic>? _kpis;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/analytics/dashboard');
      setState(() {
        _kpis = response.data['data'] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tableau de bord',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        _buildKpiGrid(),
                        const SizedBox(height: 24),
                        _buildRecentSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildKpiGrid() {
    if (_kpis == null) return const SizedBox.shrink();
    final k = _kpis!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 3 : 2;
        final items = <_KpiData>[
          _KpiData(
            'Ventes du jour',
            FormatUtils.money((k['today_revenue'] ?? 0) as int),
            Icons.trending_up,
            AppColors.success,
          ),
          _KpiData(
            'Commandes',
            '${k['today_orders'] ?? 0}',
            Icons.receipt_long,
            AppColors.primary,
          ),
          _KpiData(
            'Ticket moyen',
            FormatUtils.money((k['avg_ticket'] ?? 0) as int),
            Icons.attach_money,
            AppColors.accent,
          ),
          _KpiData(
            'Tables occupées',
            '${k['occupied_tables'] ?? 0} / ${k['total_tables'] ?? 0}',
            Icons.table_restaurant,
            AppColors.tableOccupied,
          ),
          _KpiData(
            'Commandes ouvertes',
            '${k['open_orders'] ?? 0}',
            Icons.pending_actions,
            AppColors.warning,
          ),
          _KpiData(
            'Couverts',
            '${k['today_covers'] ?? 0}',
            Icons.people,
            AppColors.info,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _KpiCard(data: items[i]),
        );
      },
    );
  }

  Widget _buildRecentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activité récente',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _kpis?['recent_orders'] != null
              ? Column(
                  children: (_kpis!['recent_orders'] as List<dynamic>).take(5).map((o) {
                    final order = o as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text('#${order['order_number'] ?? ''}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      title: Text('${order['order_type'] ?? ''} • ${order['status'] ?? ''}'),
                      subtitle: Text(FormatUtils.money((order['total_cents'] ?? 0) as int)),
                      trailing: Text(
                        order['created_at'] != null
                            ? FormatUtils.time(DateTime.tryParse(order['created_at'].toString()) ?? DateTime.now())
                            : '',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    );
                  }).toList(),
                )
              : const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Aucune commande récente')),
                ),
        ),
      ],
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _KpiData(this.label, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(data.icon, color: data.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(data.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(data.value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: data.color)),
        ],
      ),
    );
  }
}
