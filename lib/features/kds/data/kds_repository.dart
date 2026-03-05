import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final kdsRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return KdsRepository(dio: dio);
});

class KdsRepository {
  final dynamic dio;
  KdsRepository({required this.dio});

  Future<ApiResponse<List<KdsTicket>>> getTickets({String? station}) async {
    try {
      final params = <String, dynamic>{};
      if (station != null) params['station'] = station;
      final response = await dio.get('/kds/tickets', queryParameters: params);
      final list = (response.data['data'] as List<dynamic>)
          .map((e) => KdsTicket.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(list);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<void>> bumpItem(String orderItemId) async {
    try {
      await dio.post('/kds/bump/$orderItemId');
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }

  Future<ApiResponse<void>> bumpAll(String orderId) async {
    try {
      await dio.post('/kds/bump-all/$orderId');
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.error(ApiError.fromDioError(e));
    }
  }
}

class KdsTicket {
  final String orderId;
  final String orderNumber;
  final String orderType;
  final String? tableNumber;
  final String? waiterName;
  final DateTime createdAt;
  final List<KdsTicketItem> items;

  KdsTicket({
    required this.orderId,
    required this.orderNumber,
    required this.orderType,
    this.tableNumber,
    this.waiterName,
    required this.createdAt,
    this.items = const [],
  });

  factory KdsTicket.fromJson(Map<String, dynamic> json) => KdsTicket(
    orderId: json['order_id'] ?? json['id'] ?? '',
    orderNumber: json['order_number'] ?? '',
    orderType: json['order_type'] ?? 'dine_in',
    tableNumber: json['table_number'],
    waiterName: json['waiter_name'],
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    items: (json['items'] as List<dynamic>?)
        ?.map((e) => KdsTicketItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );

  Duration get elapsedTime => DateTime.now().difference(createdAt);
}

class KdsTicketItem {
  final String id;
  final String nameFr;
  final int quantity;
  final String status;
  final String? notes;
  final List<String> modifiers;

  KdsTicketItem({
    required this.id,
    required this.nameFr,
    this.quantity = 1,
    this.status = 'pending',
    this.notes,
    this.modifiers = const [],
  });

  factory KdsTicketItem.fromJson(Map<String, dynamic> json) => KdsTicketItem(
    id: json['id'] ?? '',
    nameFr: json['name_fr'] ?? '',
    quantity: json['quantity'] ?? 1,
    status: json['status'] ?? 'pending',
    notes: json['notes'],
    modifiers: (json['modifiers'] as List<dynamic>?)
        ?.map((e) => (e is Map) ? (e['name_fr'] ?? '').toString() : e.toString())
        .toList() ?? [],
  );
}
