class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final bool isAvailable;
  final String imageUrl;
  final String pharmacyId; // Vínculo crítico al marketplace

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.isAvailable,
    required this.imageUrl,
    required this.pharmacyId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category,
    'price': price,
    'isAvailable': isAvailable,
    'imageUrl': imageUrl,
    'pharmacyId': pharmacyId,
  };
}
