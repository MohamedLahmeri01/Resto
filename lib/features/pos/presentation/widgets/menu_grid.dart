import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../menu/domain/menu_models.dart';

class MenuGrid extends StatelessWidget {
  final List<MenuItem> items;
  final void Function(MenuItem) onItemTap;

  const MenuGrid({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Aucun article dans cette catégorie', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : constraints.maxWidth > 500 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _MenuItemCard(item: items[i], onTap: () => onItemTap(items[i])),
        );
      },
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const _MenuItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.is86d ? AppColors.surfaceVariant : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultIcon(),
                  ),
                )
              else
                _defaultIcon(),
              const SizedBox(height: 8),
              Text(
                item.nameFr,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: item.is86d ? AppColors.textTertiary : AppColors.textPrimary,
                  decoration: item.is86d ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                FormatUtils.money(item.basePriceCents),
                style: TextStyle(
                  color: item.is86d ? AppColors.textTertiary : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (item.is86d)
                const Text('Indisponible', style: TextStyle(color: AppColors.error, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultIcon() => Icon(Icons.restaurant_menu, size: 40, color: AppColors.textTertiary.withValues(alpha: 0.5));
}
