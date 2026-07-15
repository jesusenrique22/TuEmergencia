class PrescriptionSearchResult {
  final List<MedicationDetected> medications;
  final List<PharmacyInventoryMatch> pharmacies;
  final PharmacyInventoryMatch? bestFullCart;
  final PharmacyInventoryMatch? bestNearby;
  final bool geminiUsed;
  final bool fromCache;

  const PrescriptionSearchResult({
    required this.medications,
    required this.pharmacies,
    this.bestFullCart,
    this.bestNearby,
    this.geminiUsed = false,
    this.fromCache = false,
  });

  factory PrescriptionSearchResult.fromJson(Map<String, dynamic> json) {
    return PrescriptionSearchResult(
      medications: (json['medications'] as List<dynamic>? ?? [])
          .map((e) => MedicationDetected.fromJson(e as Map<String, dynamic>))
          .toList(),
      pharmacies: (json['pharmacies'] as List<dynamic>? ?? [])
          .map((e) => PharmacyInventoryMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      bestFullCart: json['bestFullCart'] != null
          ? PharmacyInventoryMatch.fromJson(
              json['bestFullCart'] as Map<String, dynamic>,
            )
          : null,
      bestNearby: json['bestNearby'] != null
          ? PharmacyInventoryMatch.fromJson(
              json['bestNearby'] as Map<String, dynamic>,
            )
          : null,
      geminiUsed: json['geminiUsed'] as bool? ?? false,
      fromCache: json['fromCache'] as bool? ?? false,
    );
  }
}

class MedicationDetected {
  final String detected;
  final String normalized;

  const MedicationDetected({required this.detected, required this.normalized});

  factory MedicationDetected.fromJson(Map<String, dynamic> json) {
    return MedicationDetected(
      detected: json['detected'] as String? ?? '',
      normalized: json['normalized'] as String? ?? '',
    );
  }
}

class PharmacyInventoryMatch {
  final PharmacyMatchInfo pharmacy;
  final List<MatchedProduct> items;
  final List<String> missing;
  final int completeness;
  final double subtotal;
  final double tax;
  final double total;

  const PharmacyInventoryMatch({
    required this.pharmacy,
    required this.items,
    required this.missing,
    required this.completeness,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  factory PharmacyInventoryMatch.fromJson(Map<String, dynamic> json) {
    return PharmacyInventoryMatch(
      pharmacy: PharmacyMatchInfo.fromJson(
        json['pharmacy'] as Map<String, dynamic>,
      ),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => MatchedProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      missing: (json['missing'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      completeness: json['completeness'] as int? ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PharmacyMatchInfo {
  final String id;
  final String name;
  final String address;
  final String? logoUrl;
  final double? distanceKm;

  const PharmacyMatchInfo({
    required this.id,
    required this.name,
    required this.address,
    this.logoUrl,
    this.distanceKm,
  });

  factory PharmacyMatchInfo.fromJson(Map<String, dynamic> json) {
    return PharmacyMatchInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}

class MatchedProduct {
  final String productId;
  final String name;
  final String? brand;
  final double price;
  final int stock;
  final String matchedMedication;

  const MatchedProduct({
    required this.productId,
    required this.name,
    this.brand,
    required this.price,
    required this.stock,
    required this.matchedMedication,
  });

  factory MatchedProduct.fromJson(Map<String, dynamic> json) {
    return MatchedProduct(
      productId: json['productId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: json['stock'] as int? ?? 0,
      matchedMedication: json['matchedMedication'] as String? ?? '',
    );
  }
}
