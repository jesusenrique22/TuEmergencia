import '../models/insurance_models.dart';
import '../models/insurance_data_mock.dart';

class InsuranceCalculator {
  /// Calcula el desglose financiero de un servicio según la póliza activa.
  static Map<String, double> calculateCopay({
    required double subtotal,
    required String category, // 'pharmacy', 'ambulance', 'laboratory', 'er'
    PatientPolicy? policy,
  }) {
    // 1. Intentamos usar la póliza pasada, sino la póliza del mock de forma segura
    PatientPolicy? activePolicy = policy;
    
    if (activePolicy == null) {
      try {
        activePolicy = InsuranceDataMock.activePolicies.firstWhere(
          (p) => p.status == PolicyStatus.active,
        );
      } catch (_) {
        // Si no hay póliza activa ni mock, no hay cobertura
        return {
          'subtotal': subtotal,
          'coveredAmount': 0.0,
          'totalToPay': subtotal,
          'percentage': 0.0,
        };
      }
    }

    // 2. Buscamos la cobertura para esa póliza
    InsuranceCoverage? coverage;
    
    // Si la póliza tiene la aseguradora y sus coberturas anidadas (cargadas del backend)
    if (activePolicy.insurance != null && 
        activePolicy.insurance!.coverages != null && 
        activePolicy.insurance!.coverages!.isNotEmpty) {
      coverage = activePolicy.insurance!.coverages!.first;
    } else {
      // Fallback a los mocks si no están cargadas
      try {
        coverage = InsuranceDataMock.coverages.firstWhere(
          (c) => c.insuranceId == activePolicy!.insuranceId,
        );
      } catch (_) {
        return {
          'subtotal': subtotal,
          'coveredAmount': 0.0,
          'totalToPay': subtotal,
          'percentage': 0.0,
        };
      }
    }

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
