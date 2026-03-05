import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resto/core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/table_provider.dart';
import '../../domain/table_model.dart';

class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tableProvider.notifier).loadTables());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tableProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Stats bar
          _buildStatsBar(state),
          // Section filter
          _buildSectionFilter(state),
          // Floor plan
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filteredTables.isEmpty
                    ? const Center(child: Text('Aucune table configurée'))
                    : _buildFloorPlan(state.filteredTables),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(TableState state) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          _statBadge('Disponibles', state.availableCount, AppColors.tableAvailable),
          const SizedBox(width: 16),
          _statBadge('Occupées', state.occupiedCount, AppColors.tableOccupied),
          const SizedBox(width: 16),
          _statBadge('Réservées', state.reservedCount, AppColors.tableReserved),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(tableProvider.notifier).loadTables(),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, int count, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text('$count $label', style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildSectionFilter(TableState state) {
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Toutes'),
              selected: state.selectedSectionId == null,
              onSelected: (_) => ref.read(tableProvider.notifier).selectSection(null),
            ),
          ),
          ...state.sections.map((s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(s.nameFr),
              selected: state.selectedSectionId == s.id,
              onSelected: (_) => ref.read(tableProvider.notifier).selectSection(s.id),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFloorPlan(List<RestaurantTable> tables) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 6 : constraints.maxWidth > 600 ? 4 : 3;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: tables.length,
          itemBuilder: (_, i) => _TableTile(
            table: tables[i],
            onTap: () => _showTableActions(tables[i]),
          ),
        );
      },
    );
  }

  void _showTableActions(RestaurantTable table) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Table ${table.tableNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${table.seats} places • ${table.status.name}'),
            ),
            const Divider(),
            if (table.status == TableStatus.available) ...[
              ListTile(
                leading: const Icon(Icons.restaurant, color: AppColors.tableOccupied),
                title: const Text('Marquer occupée'),
                onTap: () {
                  ref.read(tableProvider.notifier).updateTableStatus(table.id, 'occupied');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_seat, color: AppColors.tableReserved),
                title: const Text('Marquer réservée'),
                onTap: () {
                  ref.read(tableProvider.notifier).updateTableStatus(table.id, 'reserved');
                  Navigator.pop(context);
                },
              ),
            ],
            if (table.status == TableStatus.occupied)
              ListTile(
                leading: const Icon(Icons.cleaning_services, color: AppColors.tableCleaning),
                title: const Text('Nettoyage'),
                onTap: () {
                  ref.read(tableProvider.notifier).updateTableStatus(table.id, 'cleaning');
                  Navigator.pop(context);
                },
              ),
            if (table.status != TableStatus.available)
              ListTile(
                leading: const Icon(Icons.check_circle, color: AppColors.tableAvailable),
                title: const Text('Libérer'),
                onTap: () {
                  ref.read(tableProvider.notifier).updateTableStatus(table.id, 'available');
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TableTile extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;

  const _TableTile({required this.table, required this.onTap});

  Color get _color {
    switch (table.status) {
      case TableStatus.occupied: return AppColors.tableOccupied;
      case TableStatus.reserved: return AppColors.tableReserved;
      case TableStatus.cleaning: return AppColors.tableCleaning;
      case TableStatus.available: return AppColors.tableAvailable;
    }
  }

  IconData get _icon {
    switch (table.status) {
      case TableStatus.occupied: return Icons.restaurant;
      case TableStatus.reserved: return Icons.event_seat;
      case TableStatus.cleaning: return Icons.cleaning_services;
      case TableStatus.available: return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRound = table.shape == 'round';

    return Material(
      color: _color.withValues(alpha: 0.12),
      shape: isRound
          ? CircleBorder(side: BorderSide(color: _color, width: 2))
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _color, width: 2),
            ),
      child: InkWell(
        customBorder: isRound ? const CircleBorder() : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, color: _color, size: 28),
            const SizedBox(height: 4),
            Text(
              table.tableNumber,
              style: TextStyle(fontWeight: FontWeight.bold, color: _color, fontSize: 16),
            ),
            Text(
              '${table.seats} pl.',
              style: TextStyle(color: _color.withValues(alpha: 0.7), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
