import 'package:flutter/material.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../providers/pos_provider.dart';

class CartPanel extends StatelessWidget {
  final List<CartItem> cart;
  final int total;
  final bool isLoading;
  final OrderType orderType;
  final void Function(int) onRemoveItem;
  final void Function(int, int) onUpdateQty;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final void Function(OrderType) onOrderTypeChanged;

  const CartPanel({
    super.key,
    required this.cart,
    required this.total,
    required this.isLoading,
    required this.orderType,
    required this.onRemoveItem,
    required this.onUpdateQty,
    required this.onSubmit,
    required this.onClear,
    required this.onOrderTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Order type selector
          _buildOrderTypeBar(),
          const Divider(height: 1),
          // Cart items
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textTertiary),
                        SizedBox(height: 8),
                        Text('Panier vide', style: TextStyle(color: AppColors.textTertiary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.length,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemBuilder: (_, i) => _CartItemTile(
                      item: cart[i],
                      onRemove: () => onRemoveItem(i),
                      onIncrement: () => onUpdateQty(i, cart[i].quantity + 1),
                      onDecrement: () => onUpdateQty(i, cart[i].quantity - 1),
                    ),
                  ),
          ),
          // Footer
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      FormatUtils.money(total),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: cart.isEmpty ? null : onClear,
                        child: const Text('Vider'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: cart.isEmpty || isLoading ? null : onSubmit,
                        child: isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Envoyer la commande', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SegmentedButton<OrderType>(
        segments: const [
          ButtonSegment(value: OrderType.dineIn, label: Text('Sur place'), icon: Icon(Icons.restaurant, size: 18)),
          ButtonSegment(value: OrderType.takeaway, label: Text('Emporter'), icon: Icon(Icons.takeout_dining, size: 18)),
          ButtonSegment(value: OrderType.delivery, label: Text('Livraison'), icon: Icon(Icons.delivery_dining, size: 18)),
        ],
        selected: {orderType},
        onSelectionChanged: (s) => onOrderTypeChanged(s.first),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('${item.menuItem.id}_${item.notes}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            // Qty controls
            Column(
              children: [
                InkWell(
                  onTap: onIncrement,
                  child: const Icon(Icons.add_circle_outline, size: 22, color: AppColors.primary),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                InkWell(
                  onTap: onDecrement,
                  child: const Icon(Icons.remove_circle_outline, size: 22, color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Item info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menuItem.nameFr,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.selectedModifiers.isNotEmpty)
                    Text(
                      item.selectedModifiers.map((m) => m.nameFr).join(', '),
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    Text(
                      item.notes!,
                      style: const TextStyle(color: AppColors.accent, fontSize: 11, fontStyle: FontStyle.italic),
                      maxLines: 1,
                    ),
                ],
              ),
            ),
            // Price
            Text(
              FormatUtils.money(item.totalCents),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
