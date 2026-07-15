import '../../../../core/network/api_client.dart';
import '../models/insurance_models.dart';

class InsuranceApiService {
  static final InsuranceApiService instance = InsuranceApiService._();
  InsuranceApiService._();
  factory InsuranceApiService() => instance;

  final ApiClient _client = ApiClient.instance;

  /// Obtener todas las compañías de seguro activas y sus coberturas
  Future<List<HealthInsurance>> getCompanies() async {
    try {
      final response = await _client.get('api/insurance/companies', auth: true);
      if (response is List) {
        return response
            .map((item) => HealthInsurance.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener la póliza de seguro activa para el paciente
  Future<PatientPolicy?> getMyPolicy() async {
    try {
      final response = await _client.get('api/insurance/policy', auth: true);
      if (response == null || (response is Map && response.isEmpty)) {
        return null;
      }
      return PatientPolicy.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // Si la API retorna 404 de no póliza encontrada, lo manejamos como nulo
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// Registrar o actualizar una póliza de seguro para el paciente
  Future<PatientPolicy> updateMyPolicy({
    required String insuranceId,
    required String policyNumber,
    String status = 'ACTIVE',
  }) async {
    try {
      final response = await _client.post(
        'api/insurance/policy',
        {
          'insuranceId': insuranceId,
          'policyNumber': policyNumber,
          'status': status,
        },
        auth: true,
      );
      return PatientPolicy.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Calcular copago desde el servidor
  Future<Map<String, dynamic>> calculateCopay({
    required double subtotal,
    required String category,
  }) async {
    try {
      final response = await _client.post(
        'api/insurance/calculate-copay',
        {
          'subtotal': subtotal,
          'category': category,
        },
        auth: true,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener facturas e historial de liquidaciones del paciente
  Future<List<MedicalInvoice>> getMyInvoices() async {
    try {
      final response = await _client.get('api/insurance/invoices', auth: true);
      if (response is List) {
        return response
            .map((item) => MedicalInvoice.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Registrar una factura médica aprobada por seguro
  Future<MedicalInvoice> createInvoice({
    required String requestId,
    required String insuranceId,
    required double subtotal,
    required double coveredAmount,
    required double copayAmount,
    String status = 'PENDING',
  }) async {
    try {
      final response = await _client.post(
        'api/insurance/invoices',
        {
          'requestId': requestId,
          'insuranceId': insuranceId,
          'subtotal': subtotal,
          'coveredAmount': coveredAmount,
          'copayAmount': copayAmount,
          'status': status,
        },
        auth: true,
      );
      return MedicalInvoice.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
