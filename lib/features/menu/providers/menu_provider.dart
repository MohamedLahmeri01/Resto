import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/menu_repository.dart';
import '../domain/menu_models.dart';

// Menu tree (categories + items + modifiers)
class MenuState {
  final List<MenuCategory> categories;
  final bool isLoading;
  final String? error;
  final String? selectedCategoryId;

  const MenuState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategoryId,
  });

  MenuState copyWith({
    List<MenuCategory>? categories,
    bool? isLoading,
    String? error,
    String? selectedCategoryId,
  }) => MenuState(
    categories: categories ?? this.categories,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
  );

  List<MenuItem> get currentItems {
    if (selectedCategoryId == null) {
      return categories.expand((c) => c.items).toList();
    }
    return categories
        .where((c) => c.id == selectedCategoryId)
        .expand((c) => c.items)
        .toList();
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final MenuRepository _repo;
  MenuNotifier(this._repo) : super(const MenuState());

  Future<void> loadMenuTree() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.getMenuTree();
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        categories: result.data!,
        isLoading: false,
        selectedCategoryId: result.data!.isNotEmpty ? result.data!.first.id : null,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error?.message);
    }
  }

  void selectCategory(String? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  Future<void> toggle86(String itemId, bool is86d) async {
    await _repo.toggle86(itemId, is86d);
    await loadMenuTree(); // Refresh
  }
}

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final repo = ref.watch(menuRepositoryProvider);
  return MenuNotifier(repo);
});

// Convenience
final menuCategoriesProvider = Provider<List<MenuCategory>>((ref) {
  return ref.watch(menuProvider).categories;
});

final selectedCategoryItemsProvider = Provider<List<MenuItem>>((ref) {
  return ref.watch(menuProvider).currentItems;
});
