enum PharmacyRole { admin, inventory, cashier }

class PharmacyEmployee {
  final String id;
  final String name;
  final String pharmacyId;
  final PharmacyRole role;
  final String email;

  PharmacyEmployee({
    required this.id,
    required this.name,
    required this.pharmacyId,
    required this.role,
    this.email = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pharmacyId': pharmacyId,
    'role': role.toString(),
    'email': email,
  };
}
