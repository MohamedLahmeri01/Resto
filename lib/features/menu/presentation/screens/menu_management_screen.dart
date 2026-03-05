import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../data/menu_repository.dart';
import '../../domain/menu_models.dart';
import '../../providers/menu_provider.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(menuProvider.notifier).loadMenuTree());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Categories panel
                SizedBox(
                  width: 280,
                  child: _CategoriesPanel(
                    categories: state.categories,
                    selectedId: state.selectedCategoryId,
                    onSelect: (id) => ref.read(menuProvider.notifier).selectCategory(id),
                    onAdd: () => _showCategoryDialog(),
                  ),
                ),
                const VerticalDivider(width: 1),
                // Items panel
                Expanded(
                  child: _ItemsPanel(
                    items: state.currentItems,
                    onToggle86: (id, val) => ref.read(menuProvider.notifier).toggle86(id, val),
                    onAdd: () => _showItemDialog(),
                    onEdit: (item) => _showItemDialog(item: item),
                  ),
                ),
              ],
            ),
    );
  }

  void _showCategoryDialog({MenuCategory? category}) {
    final nameFrCtrl = TextEditingController(text: category?.nameFr ?? '');
    final nameArCtrl = TextEditingController(text: category?.nameAr ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(category == null ? 'Nouvelle catégorie' : 'Modifier catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameFrCtrl,
              decoration: const InputDecoration(labelText: 'Nom (FR)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameArCtrl,
              decoration: const InputDecoration(labelText: 'Nom (AR)', border: OutlineInputBorder()),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              final data = {
                'name_fr': nameFrCtrl.text.trim(),
                if (nameArCtrl.text.trim().isNotEmpty) 'name_ar': nameArCtrl.text.trim(),
              };
              final repo = ref.read(menuRepositoryProvider);
              if (category == null) {
                await repo.createCategory(data);
              } else {
                await repo.updateCategory(category.id, data);
              }
              if (mounted) {
                Navigator.pop(context);
                ref.read(menuProvider.notifier).loadMenuTree();
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showItemDialog({MenuItem? item}) {
    final nameFrCtrl = TextEditingController(text: item?.nameFr ?? '');
    final nameArCtrl = TextEditingController(text: item?.nameAr ?? '');
    final priceCtrl = TextEditingController(text: item != null ? (item.basePriceCents / 100).toStringAsFixed(0) : '');
    final descCtrl = TextEditingController(text: item?.descriptionFr ?? '');

    final state = ref.read(menuProvider);
    String? categoryId = item?.categoryId ?? state.selectedCategoryId;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'Nouvel article' : 'Modifier article'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: categoryId,
                  decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
                  items: state.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameFr))).toList(),
                  onChanged: (v) => categoryId = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameFrCtrl,
                  decoration: const InputDecoration(labelText: 'Nom (FR)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameArCtrl,
                  decoration: const InputDecoration(labelText: 'Nom (AR)', border: OutlineInputBorder()),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Prix (DA)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (FR)', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
              final data = {
                'category_id': categoryId,
                'name_fr': nameFrCtrl.text.trim(),
                if (nameArCtrl.text.trim().isNotEmpty) 'name_ar': nameArCtrl.text.trim(),
                'base_price_cents': price * 100,
                if (descCtrl.text.trim().isNotEmpty) 'description_fr': descCtrl.text.trim(),
              };
              final repo = ref.read(menuRepositoryProvider);
              if (item == null) {
                await repo.createItem(data);
              } else {
                await repo.updateItem(item.id, data);
              }
              if (mounted) {
                Navigator.pop(context);
                ref.read(menuProvider.notifier).loadMenuTree();
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _CategoriesPanel extends StatelessWidget {
  final List<MenuCategory> categories;
  final String? selectedId;
  final void Function(String) onSelect;
  final VoidCallback onAdd;

  const _CategoriesPanel({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Catégories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(icon: const Icon(Icons.add_circle), onPressed: onAdd),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final selected = cat.id == selectedId;
                return ListTile(
                  selected: selected,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                  title: Text(cat.nameFr, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                  trailing: Text('${cat.items.length}', style: const TextStyle(color: AppColors.textTertiary)),
                  onTap: () => onSelect(cat.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsPanel extends StatelessWidget {
  final List<MenuItem> items;
  final void Function(String, bool) onToggle86;
  final VoidCallback onAdd;
  final void Function(MenuItem) onEdit;

  const _ItemsPanel({
    required this.items,
    required this.onToggle86,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Articles (${items.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Aucun article'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.is86d ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          item.is86d ? Icons.block : Icons.restaurant_menu,
                          color: item.is86d ? AppColors.error : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item.nameFr,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          decoration: item.is86d ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(FormatUtils.money(item.basePriceCents)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: !item.is86d,
                            onChanged: (val) => onToggle86(item.id, !val),
                            activeColor: AppColors.success,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => onEdit(item),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
