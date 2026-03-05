enum UserRole { superAdmin, owner, manager, cashier, waiter, chef, host, staff }

enum OrderType { dineIn, takeaway, delivery }

enum OrderStatus { draft, open, preparing, ready, served, closed, voided, refunded }

enum OrderItemStatus { pending, preparing, ready, served, voided }

enum TableStatus { available, occupied, reserved, cleaning }

enum PaymentMethod { cash, card, mobile }

enum PaymentStatus { pending, captured, refunded, failed }

enum ShiftStatus { scheduled, active, completed, noShow }

enum ReservationStatus { pending, confirmed, seated, completed, noShow, cancelled }

enum POStatus { draft, submitted, approved, received, cancelled }

extension UserRoleX on UserRole {
  String get value {
    switch (this) {
      case UserRole.superAdmin: return 'super_admin';
      case UserRole.owner: return 'owner';
      case UserRole.manager: return 'manager';
      case UserRole.cashier: return 'cashier';
      case UserRole.waiter: return 'waiter';
      case UserRole.chef: return 'chef';
      case UserRole.host: return 'host';
      case UserRole.staff: return 'staff';
    }
  }

  static UserRole fromString(String s) {
    switch (s) {
      case 'super_admin': return UserRole.superAdmin;
      case 'owner': return UserRole.owner;
      case 'manager': return UserRole.manager;
      case 'cashier': return UserRole.cashier;
      case 'waiter': return UserRole.waiter;
      case 'chef': return UserRole.chef;
      case 'host': return UserRole.host;
      default: return UserRole.staff;
    }
  }
}

extension OrderTypeX on OrderType {
  String get value {
    switch (this) {
      case OrderType.dineIn: return 'dine_in';
      case OrderType.takeaway: return 'takeaway';
      case OrderType.delivery: return 'delivery';
    }
  }
}

extension OrderStatusX on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.draft: return 'draft';
      case OrderStatus.open: return 'open';
      case OrderStatus.preparing: return 'preparing';
      case OrderStatus.ready: return 'ready';
      case OrderStatus.served: return 'served';
      case OrderStatus.closed: return 'closed';
      case OrderStatus.voided: return 'voided';
      case OrderStatus.refunded: return 'refunded';
    }
  }
}

extension TableStatusX on TableStatus {
  String get value {
    switch (this) {
      case TableStatus.available: return 'available';
      case TableStatus.occupied: return 'occupied';
      case TableStatus.reserved: return 'reserved';
      case TableStatus.cleaning: return 'cleaning';
    }
  }
}
