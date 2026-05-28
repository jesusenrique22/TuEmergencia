import 'pharmacy.dart';
import 'product.dart';

class OptimizedCartResult {
  final Pharmacy pharmacy;
  final List<Product> medications;
  final double subtotal;
  final double tax;
  final double total;

  OptimizedCartResult({
    required this.pharmacy,
    required this.medications,
    required this.subtotal,
    required this.tax,
    required this.total,
  });
}
