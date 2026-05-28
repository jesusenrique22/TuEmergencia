class Pharmacy {
  final String id;
  final String name;
  final String logoUrl;
  final bool isActive;
  final String address;

  Pharmacy({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.isActive = true,
    this.address = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logoUrl': logoUrl,
    'isActive': isActive,
    'address': address,
  };
}
