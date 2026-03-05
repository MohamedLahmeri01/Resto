import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../menu/domain/menu_models.dart';
import '../../../menu/providers/menu_provider.dart';
import '../../providers/pos_provider.dart';
import '../widgets/cart_panel.dart';
import '../widgets/menu_grid.dart';
import '../widgets/modifier_dialog.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(menuProvider.notifier).loadMenuTree();
      ref.read(posProvider.notifier).loadActiveOrders();
    });
  }

  void _onItemTap(MenuItem item) {
    if (item.is86d) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article indisponible (86d)'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (item.modifierGroups.isNotEmpty) {
      _showModifierDialog(item);
    } else {
      ref.read(posProvider.notifier).addToCart(item);
    }
  }

  void _showModifierDialog(MenuItem item) {
    showDialog(
      context: context,
      builder: (_) => ModifierDialog(
        item: item,
        onConfirm: (modifiers, notes) {
          ref.read(posProvider.notifier).addToCart(item, modifiers: modifiers, notes: notes);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final posState = ref.watch(posProvider);
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          // Menu area (left)
          Expanded(
            flex: isWide ? 3 : 2,
            child: Column(
              children: [
                // Category tabs
                _buildCategoryBar(menuState),
                // Menu grid
                Expanded(
                  child: menuState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : MenuGrid(
                          items: menuState.currentItems,
                          onItemTap: _onItemTap,
                        ),
                ),
              ],
            ),
          ),
          // Divider
          const VerticalDivider(width: 1),
          // Cart panel (right)
          SizedBox(
            width: isWide ? 380 : 300,
            child: CartPanel(
              cart: posState.cart,
              total: posState.cartTotal,
              isLoading: posState.isLoading,
              orderType: posState.orderType,
              onRemoveItem: (i) => ref.read(posProvider.notifier).removeFromCart(i),
              onUpdateQty: (i, q) => ref.read(posProvider.notifier).updateQuantity(i, q),
              onSubmit: () => ref.read(posProvider.notifier).submitOrder(),
              onClear: () => ref.read(posProvider.notifier).clearCart(),
              onOrderTypeChanged: (t) => ref.read(posProvider.notifier).setOrderType(t),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(MenuState menuState) {
    return Container(
      height: 56,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: menuState.categories.length,
        itemBuilder: (_, i) {
          final cat = menuState.categories[i];
          final isSelected = cat.id == menuState.selectedCategoryId;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat.nameFr),
              selected: isSelected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              onSelected: (_) => ref.read(menuProvider.notifier).selectCategory(cat.id),
            ),
          );
        },
      ),
    );
  }
}
