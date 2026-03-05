import '../../../core/constants/enums.dart';

class RestaurantTable {
  final String id;
  final String branchId;
  final String? sectionId;
  final String? sectionName;
  final String tableNumber;
  final int seats;
  final double posX;
  final double posY;
  final double width;
  final double height;
  final String shape;
  final TableStatus status;
  final String? currentOrderId;
  final DateTime? occupiedSince;

  RestaurantTable({
    required this.id,
    required this.branchId,
    this.sectionId,
    this.sectionName,
    required this.tableNumber,
    this.seats = 4,
    this.posX = 0,
    this.posY = 0,
    this.width = 80,
    this.height = 80,
    this.shape = 'square',
    this.status = TableStatus.available,
    this.currentOrderId,
    this.occupiedSince,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) => RestaurantTable(
    id: json['id'] ?? '',
    branchId: json['branch_id'] ?? '',
    sectionId: json['section_id'],
    sectionName: json['section_name_fr'],
    tableNumber: json['table_number'] ?? '',
    seats: json['seats'] ?? 4,
    posX: (json['pos_x'] ?? 0).toDouble(),
    posY: (json['pos_y'] ?? 0).toDouble(),
    width: (json['width'] ?? 80).toDouble(),
    height: (json['height'] ?? 80).toDouble(),
    shape: json['shape'] ?? 'square',
    status: _parseTableStatus(json['status'] ?? 'available'),
    currentOrderId: json['current_order_id'],
    occupiedSince: json['occupied_since'] != null
        ? DateTime.tryParse(json['occupied_since'].toString())
        : null,
  );
}

TableStatus _parseTableStatus(String s) {
  switch (s) {
    case 'occupied': return TableStatus.occupied;
    case 'reserved': return TableStatus.reserved;
    case 'cleaning': return TableStatus.cleaning;
    default: return TableStatus.available;
  }
}

class FloorSection {
  final String id;
  final String nameFr;
  final String? nameAr;
  final List<RestaurantTable> tables;

  FloorSection({
    required this.id,
    required this.nameFr,
    this.nameAr,
    this.tables = const [],
  });

  factory FloorSection.fromJson(Map<String, dynamic> json) => FloorSection(
    id: json['id'] ?? '',
    nameFr: json['name_fr'] ?? '',
    nameAr: json['name_ar'],
  );
}
