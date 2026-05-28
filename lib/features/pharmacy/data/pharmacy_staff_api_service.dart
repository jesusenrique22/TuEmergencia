import '../../../core/network/api_client.dart';

final _client = ApiClient();

class PharmacyOrderDto {
  final String id;
  final String productName;
  final int quantity;
  final double total;
  final String status;

  PharmacyOrderDto({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.total,
    required this.status,
  });

  factory PharmacyOrderDto.fromJson(Map<String, dynamic> j) => PharmacyOrderDto(
        id: j['_id']?.toString() ?? '',
        productName: j['productName'] as String? ?? '',
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        total: (j['total'] as num?)?.toDouble() ?? 0,
        status: j['status'] as String? ?? 'PENDING',
      );
}

class PharmacyStaffApiService {
  Future<Map<String, dynamic>> getMyContext() async {
    final data = await _client.get('/api/pharmacy-staff/me');
    return data as Map<String, dynamic>;
  }

  Future<List<PharmacyOrderDto>> listOrders() async {
    final data = await _client.get('/api/pharmacy-staff/orders');
    return (data as List)
        .map((e) => PharmacyOrderDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client.patch('/api/pharmacy-staff/orders/$orderId', {'status': status});
  }
}
