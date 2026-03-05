import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _ingredients = [];
  List<dynamic> _suppliers = [];
  List<dynamic> _purchaseOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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
        dio.get('/inventory/ingredients'),
        dio.get('/inventory/suppliers'),
        dio.get('/inventory/purchase-orders'),
      ]);
      setState(() {
        _ingredients = results[0].data['data'] as List<dynamic>;
        _suppliers = results[1].data['data'] as List<dynamic>;
        _purchaseOrders = (results[2].data['data'] ?? []) as List<dynamic>;
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
                Tab(text: 'Ingrédients', icon: Icon(Icons.inventory_2)),
                Tab(text: 'Fournisseurs', icon: Icon(Icons.local_shipping)),
                Tab(text: 'Commandes achat', icon: Icon(Icons.shopping_bag)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildIngredientsList(),
                      _buildSuppliersList(),
                      _buildPurchaseOrdersList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsList() {
    if (_ingredients.isEmpty) return const Center(child: Text('Aucun ingrédient'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _ingredients.length,
      itemBuilder: (_, i) {
        final ing = _ingredients[i] as Map<String, dynamic>;
        final qty = (ing['current_qty'] ?? 0) as num;
        final min = (ing['min_qty'] ?? 0) as num;
        final isLow = qty <= min;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isLow ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
              child: Icon(Icons.inventory, color: isLow ? AppColors.error : AppColors.success, size: 20),
            ),
            title: Text(ing['name_fr'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text('${qty} ${ing['unit'] ?? ''} • Min: ${min} ${ing['unit'] ?? ''}'),
            trailing: isLow
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)),
                    child: const Text('Stock bas', style: TextStyle(color: Colors.white, fontSize: 11)),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildSuppliersList() {
    if (_suppliers.isEmpty) return const Center(child: Text('Aucun fournisseur'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _suppliers.length,
      itemBuilder: (_, i) {
        final sup = _suppliers[i] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.business, size: 20)),
            title: Text(sup['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(sup['contact_email'] ?? sup['phone'] ?? ''),
          ),
        );
      },
    );
  }

  Widget _buildPurchaseOrdersList() {
    if (_purchaseOrders.isEmpty) return const Center(child: Text('Aucune commande achat'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _purchaseOrders.length,
      itemBuilder: (_, i) {
        final po = _purchaseOrders[i] as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.shopping_bag, color: AppColors.primary, size: 20),
            ),
            title: Text('PO #${po['po_number'] ?? po['id']?.toString().substring(0, 8) ?? ''}'),
            subtitle: Text('Statut: ${po['status'] ?? 'draft'}'),
            trailing: Text('${po['total_cents'] != null ? ((po['total_cents'] as num) / 100).toStringAsFixed(0) : '-'} DA'),
          ),
        );
      },
    );
  }
}
