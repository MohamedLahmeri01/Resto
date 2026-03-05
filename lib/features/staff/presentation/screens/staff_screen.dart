import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _staff = [];
  List<dynamic> _shifts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final dio = ref.read(dioProvider);
    try {
      final results = await Future.wait([
        dio.get('/staff'),
        dio.get('/staff/shifts'),
      ]);
      setState(() {
        _staff = results[0].data['data'] as List<dynamic>;
        _shifts = (results[1].data['data'] ?? []) as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Équipe', icon: Icon(Icons.people)),
                Tab(text: 'Planning', icon: Icon(Icons.calendar_month)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildStaffList(),
                      _buildShiftsList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList() {
    if (_staff.isEmpty) return const Center(child: Text('Aucun membre'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _staff.length,
      itemBuilder: (_, i) {
        final s = _staff[i] as Map<String, dynamic>;
        final isActive = s['is_active'] == true || s['is_active'] == 1;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              child: Text(
                '${(s['first_name_fr'] ?? '?')[0]}${(s['last_name_fr'] ?? '?')[0]}'.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.primary : Colors.grey,
                ),
              ),
            ),
            title: Text(
              '${s['first_name_fr'] ?? ''} ${s['last_name_fr'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(s['role'] ?? ''),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isActive ? 'Actif' : 'Inactif',
                style: TextStyle(
                  color: isActive ? AppColors.success : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShiftsList() {
    if (_shifts.isEmpty) return const Center(child: Text('Aucun planning'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _shifts.length,
      itemBuilder: (_, i) {
        final shift = _shifts[i] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.access_time, size: 20)),
            title: Text(shift['user_name'] ?? 'Staff'),
            subtitle: Text('${shift['shift_date'] ?? ''} • ${shift['start_time'] ?? ''} - ${shift['end_time'] ?? ''}'),
            trailing: Text(shift['status'] ?? '', style: const TextStyle(fontSize: 12)),
          ),
        );
      },
    );
  }
}
