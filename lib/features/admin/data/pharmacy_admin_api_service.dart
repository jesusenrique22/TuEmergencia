import '../../../core/network/api_client.dart';

final _client = ApiClient();

class PharmacyProductDto {
  final String id;
  final String name;
  final String? brand;
  final double price;
  final int stock;
  final bool isAvailable;

  PharmacyProductDto({
    required this.id,
    required this.name,
    this.brand,
    required this.price,
    required this.stock,
    required this.isAvailable,
  });

  factory PharmacyProductDto.fromJson(Map<String, dynamic> j) => PharmacyProductDto(
        id: j['_id']?.toString() ?? '',
        name: j['name'] as String? ?? '',
        brand: j['brand'] as String?,
        price: (j['price'] as num?)?.toDouble() ?? 0,
        stock: (j['stock'] as num?)?.toInt() ?? 0,
        isAvailable: j['isAvailable'] as bool? ?? true,
      );
}

class PharmacyStaffCreateResult {
  final String email;
  final String name;
  final String temporaryPassword;

  PharmacyStaffCreateResult({
    required this.email,
    required this.name,
    required this.temporaryPassword,
  });

  factory PharmacyStaffCreateResult.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? {};
    return PharmacyStaffCreateResult(
      email: user['email'] as String? ?? '',
      name: user['name'] as String? ?? '',
      temporaryPassword: j['temporaryPassword'] as String? ?? '',
    );
  }
}

class PharmacyAdminApiService {
  Future<Map<String, dynamic>> getMyContext() async {
    final data = await _client.get('/api/pharmacy-admin/me');
    return data as Map<String, dynamic>;
  }

  Future<Map<String, int>> getStats() async {
    final data = await _client.get('/api/pharmacy-admin/stats');
    final m = data as Map<String, dynamic>;
    return {
      'products': (m['products'] as num?)?.toInt() ?? 0,
      'orders': (m['orders'] as num?)?.toInt() ?? 0,
      'pendingReview': (m['pendingReview'] as num?)?.toInt() ?? 0,
    };
  }

  Future<List<PharmacyProductDto>> listProducts() async {
    final data = await _client.get('/api/pharmacy-admin/products');
    return (data as List)
        .map((e) => PharmacyProductDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PharmacyProductDto> createProduct({
    required String name,
    required double price,
    int stock = 0,
    String? brand,
    String? category,
  }) async {
    final data = await _client.post(
      '/api/pharmacy-admin/products',
      {
        'name': name,
        'price': price,
        'stock': stock,
        'brand': ?brand,
        'category': ?category,
        'isAvailable': true,
      },
      auth: true,
    );
    return PharmacyProductDto.fromJson(data);
  }

  Future<PharmacyStaffCreateResult> createStaff({
    required String name,
    required String email,
    required String role,
    String? phone,
  }) async {
    final data = await _client.post(
      '/api/pharmacy-admin/staff',
      {
        'name': name.trim(),
        'email': email.trim(),
        'phone': ?phone?.trim(),
        'role': role,
      },
      auth: true,
    );
    return PharmacyStaffCreateResult.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> listStaff() async {
    final data = await _client.get('/api/pharmacy-admin/staff');
    return (data as List).cast<Map<String, dynamic>>();
  }
}
