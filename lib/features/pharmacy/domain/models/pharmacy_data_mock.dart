import 'pharmacy.dart';
import 'pharmacy_employee.dart';
import 'product.dart';

class PharmacyDataMock {
  static final List<Pharmacy> pharmacies = [
    Pharmacy(
      id: 'ph-001',
      name: 'FarmaVita Central',
      logoUrl:
          'https://images.unsplash.com/photo-1586015555751-63bb77f4322a?auto=format&fit=crop&q=80&w=100',
      address: 'Av. Libertador #123',
    ),
    Pharmacy(
      id: 'ph-002',
      name: 'EcoMedic Express',
      logoUrl:
          'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=100',
      address: 'Calle 50 con Calle 72',
    ),
  ];

  static final List<PharmacyEmployee> employees = [
    PharmacyEmployee(
      id: 'emp-001',
      name: 'Carlos Admin',
      pharmacyId: 'ph-001',
      role: PharmacyRole.admin,
    ),
    PharmacyEmployee(
      id: 'emp-002',
      name: 'Ana Stock',
      pharmacyId: 'ph-001',
      role: PharmacyRole.inventory,
    ),
    PharmacyEmployee(
      id: 'emp-003',
      name: 'Luis Cajero',
      pharmacyId: 'ph-002',
      role: PharmacyRole.cashier,
    ),
    PharmacyEmployee(
      id: 'emp-004',
      name: 'Sofía Admin',
      pharmacyId: 'ph-002',
      role: PharmacyRole.admin,
    ),
  ];

  static final List<Product> products = [
    Product(
      id: 'prod-001',
      name: 'Amoxicilina 500mg',
      brand: 'Sandoz',
      category: 'Antibióticos',
      price: 15.50,
      isAvailable: true,
      imageUrl:
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=200',
      pharmacyId: 'ph-001',
    ),
    Product(
      id: 'prod-002',
      name: 'Ibuprofeno 600mg',
      brand: 'Advil',
      category: 'Analgésicos',
      price: 8.20,
      isAvailable: true,
      imageUrl:
          'https://images.unsplash.com/photo-1550572017-ed200224484c?auto=format&fit=crop&q=80&w=200',
      pharmacyId: 'ph-001',
    ),
    Product(
      id: 'prod-003',
      name: 'Loratadina 10mg',
      brand: 'Claritine',
      category: 'Antialérgicos',
      price: 12.00,
      isAvailable: true,
      imageUrl:
          'https://images.unsplash.com/photo-1587854692152-cbe660dbbb88?auto=format&fit=crop&q=80&w=200',
      pharmacyId: 'ph-002',
    ),
    Product(
      id: 'prod-004',
      name: 'Omeprazol 20mg',
      brand: 'Genfar',
      category: 'Gastrointestinal',
      price: 10.45,
      isAvailable: true,
      imageUrl:
          'https://images.unsplash.com/photo-1471864190281-ad5f9f8162e6?auto=format&fit=crop&q=80&w=200',
      pharmacyId: 'ph-002',
    ),
  ];
}
