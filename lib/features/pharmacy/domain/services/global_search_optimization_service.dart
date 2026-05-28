import '../models/product.dart';
import '../models/optimized_cart_result.dart';
import '../models/pharmacy_data_mock.dart';

class GlobalSearchOptimizationService {
  static const double _ivaRate = 0.12;

  /// Encuentra la farmacia que ofrece el costo total más bajo para una lista de nombres de medicamentos.
  /// Solo considera farmacias que tengan TODOS los medicamentos solicitados en stock.
  OptimizedCartResult? findBestPharmacyCart(List<String> medicationNames) {
    if (medicationNames.isEmpty) return null;

    final List<OptimizedCartResult> potentialCarts = PharmacyDataMock.pharmacies
        .map((pharmacy) {
          // 1. Buscamos los productos solicitados en esta farmacia específica
          final List<Product> foundProducts = PharmacyDataMock.products
              .where(
                (product) =>
                    product.pharmacyId == pharmacy.id &&
                    product.isAvailable &&
                    medicationNames.any(
                      (name) => product.name.toLowerCase().contains(
                        name.toLowerCase(),
                      ),
                    ),
              )
              .toList();

          // 2. Verificamos si la farmacia tiene el set completo
          // Nota: Esta lógica es simplificada. En producción usaríamos IDs únicos.
          if (foundProducts.length < medicationNames.length) return null;

          // 3. Calculamos financieros mediante programación funcional
          final double subtotal = foundProducts.fold(
            0.0,
            (sum, p) => sum + p.price,
          );
          final double tax = subtotal * _ivaRate;
          final double total = subtotal + tax;

          return OptimizedCartResult(
            pharmacy: pharmacy,
            medications: foundProducts,
            subtotal: subtotal,
            tax: tax,
            total: total,
          );
        })
        .whereType<
          OptimizedCartResult
        >() // Filtramos los nulls (farmacias incompletas)
        .toList();

    if (potentialCarts.isEmpty) return null;

    // 4. Encontramos el ganador: la farmacia con el total más bajo
    return potentialCarts.reduce(
      (min, current) => current.total < min.total ? current : min,
    );
  }
}
