import '../../../core/constants/enums.dart';

class Order {
  final String id;
  final String tenantId;
  final String branchId;
  final String? tableId;
  final String? tableNumber;
  final String? waiterId;
  final String? waiterName;
  final String? customerId;
  final String orderNumber;
  final OrderType orderType;
  final OrderStatus status;
  final int subtotalCents;
  final int discountCents;
  final int taxCents;
  final int totalCents;
  final int coversCount;
  final String? notes;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.tenantId,
    required this.branchId,
    this.tableId,
    this.tableNumber,
    this.waiterId,
    this.waiterName,
    this.customerId,
    required this.orderNumber,
    this.orderType = OrderType.dineIn,
    this.status = OrderStatus.draft,
    this.subtotalCents = 0,
    this.discountCents = 0,
    this.taxCents = 0,
    this.totalCents = 0,
    this.coversCount = 1,
    this.notes,
    this.items = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] ?? '',
    tenantId: json['tenant_id'] ?? '',
    branchId: json['branch_id'] ?? '',
    tableId: json['table_id'],
    tableNumber: json['table_number'],
    waiterId: json['waiter_id'],
    waiterName: json['waiter_name'],
    customerId: json['customer_id'],
    orderNumber: json['order_number'] ?? '',
    orderType: _parseOrderType(json['order_type'] ?? 'dine_in'),
    status: _parseOrderStatus(json['status'] ?? 'draft'),
    subtotalCents: json['subtotal_cents'] ?? 0,
    discountCents: json['discount_cents'] ?? 0,
    taxCents: json['tax_cents'] ?? 0,
    totalCents: json['total_cents'] ?? 0,
    coversCount: json['covers_count'] ?? 1,
    notes: json['notes'],
    items: (json['items'] as List<dynamic>?)
        ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
  );
}

class OrderItem {
  final String id;
  final String itemId;
  final String nameFr;
  final String? nameAr;
  final int quantity;
  final int unitPriceCents;
  final int totalPriceCents;
  final OrderItemStatus status;
  final int courseNumber;
  final String? prepStation;
  final String? notes;
  final List<OrderItemModifier> modifiers;

  OrderItem({
    required this.id,
    required this.itemId,
    required this.nameFr,
    this.nameAr,
    this.quantity = 1,
    this.unitPriceCents = 0,
    this.totalPriceCents = 0,
    this.status = OrderItemStatus.pending,
    this.courseNumber = 1,
    this.prepStation,
    this.notes,
    this.modifiers = const [],
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] ?? '',
    itemId: json['item_id'] ?? '',
    nameFr: json['name_fr'] ?? '',
    nameAr: json['name_ar'],
    quantity: json['quantity'] ?? 1,
    unitPriceCents: json['unit_price_cents'] ?? 0,
    totalPriceCents: json['total_price_cents'] ?? 0,
    status: _parseItemStatus(json['status'] ?? 'pending'),
    courseNumber: json['course_number'] ?? 1,
    prepStation: json['prep_station'],
    notes: json['notes'],
    modifiers: (json['modifiers'] as List<dynamic>?)
        ?.map((e) => OrderItemModifier.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class OrderItemModifier {
  final String id;
  final String modifierId;
  final String nameFr;
  final String? nameAr;
  final int priceCents;

  OrderItemModifier({
    required this.id,
    required this.modifierId,
    required this.nameFr,
    this.nameAr,
    this.priceCents = 0,
  });

  factory OrderItemModifier.fromJson(Map<String, dynamic> json) => OrderItemModifier(
    id: json['id'] ?? '',
    modifierId: json['modifier_id'] ?? '',
    nameFr: json['name_fr'] ?? '',
    nameAr: json['name_ar'],
    priceCents: json['price_cents'] ?? 0,
  );
}

OrderType _parseOrderType(String s) {
  switch (s) {
    case 'takeaway': return OrderType.takeaway;
    case 'delivery': return OrderType.delivery;
    default: return OrderType.dineIn;
  }
}

OrderStatus _parseOrderStatus(String s) {
  switch (s) {
    case 'open': return OrderStatus.open;
    case 'preparing': return OrderStatus.preparing;
    case 'ready': return OrderStatus.ready;
    case 'served': return OrderStatus.served;
    case 'closed': return OrderStatus.closed;
    case 'voided': return OrderStatus.voided;
    case 'refunded': return OrderStatus.refunded;
    default: return OrderStatus.draft;
  }
}

OrderItemStatus _parseItemStatus(String s) {
  switch (s) {
    case 'preparing': return OrderItemStatus.preparing;
    case 'ready': return OrderItemStatus.ready;
    case 'served': return OrderItemStatus.served;
    case 'voided': return OrderItemStatus.voided;
    default: return OrderItemStatus.pending;
  }
}
