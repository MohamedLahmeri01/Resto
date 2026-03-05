import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/enums.dart';
import '../../menu/domain/menu_models.dart';
import '../data/order_repository.dart';
import '../domain/order_model.dart';

// Cart item before sending to server
class CartItem {
  final MenuItem menuItem;
  int quantity;
  final List<Modifier> selectedModifiers;
  final String? notes;
  final int courseNumber;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.selectedModifiers = const [],
    this.notes,
    this.courseNumber = 1,
  });

  int get totalCents {
    final modCents = selectedModifiers.fold<int>(0, (sum, m) => sum + m.priceDeltaCents);
    return (menuItem.basePriceCents + modCents) * quantity;
  }
}

// POS state
class PosState {
  final Order? currentOrder;
  final List<CartItem> cart;
  final List<Order> activeOrders;
  final bool isLoading;
  final String? error;
  final OrderType orderType;
  final String? tableId;
  final int coversCount;

  const PosState({
    this.currentOrder,
    this.cart = const [],
    this.activeOrders = const [],
    this.isLoading = false,
    this.error,
    this.orderType = OrderType.dineIn,
    this.tableId,
    this.coversCount = 1,
  });

  PosState copyWith({
    Order? currentOrder,
    List<CartItem>? cart,
    List<Order>? activeOrders,
    bool? isLoading,
    String? error,
    OrderType? orderType,
    String? tableId,
    int? coversCount,
  }) => PosState(
    currentOrder: currentOrder ?? this.currentOrder,
    cart: cart ?? this.cart,
    activeOrders: activeOrders ?? this.activeOrders,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    orderType: orderType ?? this.orderType,
    tableId: tableId ?? this.tableId,
    coversCount: coversCount ?? this.coversCount,
  );

  int get cartTotal => cart.fold<int>(0, (sum, item) => sum + item.totalCents);
}

class PosNotifier extends StateNotifier<PosState> {
  final OrderRepository _repo;
  PosNotifier(this._repo) : super(const PosState());

  // Cart management
  void addToCart(MenuItem item, {List<Modifier> modifiers = const [], String? notes}) {
    final existing = state.cart.indexWhere(
      (c) => c.menuItem.id == item.id && c.notes == notes && _modListEquals(c.selectedModifiers, modifiers),
    );
    if (existing >= 0) {
      final updated = List<CartItem>.from(state.cart);
      updated[existing].quantity++;
      state = state.copyWith(cart: updated);
    } else {
      state = state.copyWith(
        cart: [...state.cart, CartItem(menuItem: item, selectedModifiers: modifiers, notes: notes)],
      );
    }
  }

  void removeFromCart(int index) {
    final updated = List<CartItem>.from(state.cart)..removeAt(index);
    state = state.copyWith(cart: updated);
  }

  void updateQuantity(int index, int qty) {
    if (qty <= 0) {
      removeFromCart(index);
      return;
    }
    final updated = List<CartItem>.from(state.cart);
    updated[index].quantity = qty;
    state = state.copyWith(cart: updated);
  }

  void clearCart() {
    state = state.copyWith(cart: []);
  }

  void setOrderType(OrderType type) {
    state = state.copyWith(orderType: type);
  }

  void setTable(String? tableId) {
    state = state.copyWith(tableId: tableId);
  }

  void setCovers(int count) {
    state = state.copyWith(coversCount: count);
  }

  // Send order to server
  Future<bool> submitOrder() async {
    if (state.cart.isEmpty) return false;
    state = state.copyWith(isLoading: true, error: null);

    final items = state.cart.map((c) => {
      'item_id': c.menuItem.id,
      'quantity': c.quantity,
      'course_number': c.courseNumber,
      if (c.notes != null) 'notes': c.notes,
      if (c.selectedModifiers.isNotEmpty)
        'modifiers': c.selectedModifiers.map((m) => {'modifier_id': m.id}).toList(),
    }).toList();

    final data = <String, dynamic>{
      'order_type': state.orderType.value,
      'items': items,
      'covers_count': state.coversCount,
    };
    if (state.tableId != null) data['table_id'] = state.tableId;

    final result = await _repo.createOrder(data);
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        currentOrder: result.data,
        cart: [],
        isLoading: false,
      );
      await loadActiveOrders();
      return true;
    }
    state = state.copyWith(isLoading: false, error: result.error?.message);
    return false;
  }

  // Add items to existing open order
  Future<bool> addItemsToOrder(String orderId) async {
    if (state.cart.isEmpty) return false;
    state = state.copyWith(isLoading: true, error: null);

    final items = state.cart.map((c) => {
      'item_id': c.menuItem.id,
      'quantity': c.quantity,
      'course_number': c.courseNumber,
      if (c.notes != null) 'notes': c.notes,
      if (c.selectedModifiers.isNotEmpty)
        'modifiers': c.selectedModifiers.map((m) => {'modifier_id': m.id}).toList(),
    }).toList();

    final result = await _repo.addItems(orderId, items);
    if (result.isSuccess) {
      state = state.copyWith(currentOrder: result.data, cart: [], isLoading: false);
      return true;
    }
    state = state.copyWith(isLoading: false, error: result.error?.message);
    return false;
  }

  Future<void> loadActiveOrders() async {
    final result = await _repo.getOrders(status: 'open');
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(activeOrders: result.data!);
    }
  }

  Future<void> selectOrder(String orderId) async {
    final result = await _repo.getOrder(orderId);
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(currentOrder: result.data);
    }
  }

  bool _modListEquals(List<Modifier> a, List<Modifier> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}

final posProvider = StateNotifierProvider<PosNotifier, PosState>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return PosNotifier(repo);
});
