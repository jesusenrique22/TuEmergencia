import '../models/insurance_models.dart';
import '../models/insurance_data_mock.dart';

class InsuranceCalculator {
  /// Calcula el desglose financiero de un servicio según la póliza activa.
  static Map<String, double> calculateCopay({
    required double subtotal,
    required String category, // 'pharmacy', 'ambulance', 'laboratory', 'er'
  }) {
    // 1. Buscamos si el paciente tiene una póliza activa (pat-123 es el usuario por defecto)
    final activePolicy = InsuranceDataMock.activePolicies.firstWhere(
      (p) => p.status == PolicyStatus.active,
      orElse: () => throw Exception('No active policy found'),
    );

    // 2. Buscamos la cobertura para esa póliza
    final coverage = InsuranceDataMock.coverages.firstWhere(
      (c) => c.insuranceId == activePolicy.insuranceId,
    );

    // 3. Obtenemos el porcentaje según la categoría
    double percentage = 0.0;
    switch (category) {
      case 'pharmacy':
        percentage = coverage.pharmacyPercentage;
        break;
      case 'ambulance':
        percentage = coverage.ambulancePercentage;
        break;
      case 'laboratory':
        percentage = coverage.laboratoryPercentage;
        break;
      case 'er':
        percentage = coverage.erConsultationPercentage;
        break;
    }

    double coveredAmount = subtotal * percentage;

    // Validar límite máximo (simplificado para el prototipo)
    if (coveredAmount > coverage.maxLimit) {
      coveredAmount = coverage.maxLimit;
    }

    double totalToPay = subtotal - coveredAmount;

    return {
      'subtotal': subtotal,
      'coveredAmount': coveredAmount,
      'totalToPay': totalToPay,
      'percentage': percentage,
    };
  }
}
