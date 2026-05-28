import 'insurance_models.dart';

class InsuranceDataMock {
  static final List<HealthInsurance> companies = [
    HealthInsurance(
      id: 'ins-001',
      name: 'Seguros Mercantil',
      logoUrl:
          'https://images.unsplash.com/photo-1599305090598-fe179d501c27?auto=format&fit=crop&q=80&w=100',
      clinicId: null, // Global
    ),
    HealthInsurance(
      id: 'ins-002',
      name: 'Mapfre Global',
      logoUrl:
          'https://images.unsplash.com/photo-1560179707-f14e90ef3623?auto=format&fit=crop&q=80&w=100',
      clinicId: null, // Global
    ),
    HealthInsurance(
      id: 'ins-003',
      name: 'Plan Exclusivo Méndez Gimón',
      logoUrl:
          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&q=80&w=100',
      clinicId: 'clinic-001', // Anclado a una clínica
    ),
  ];

  static final List<InsuranceCoverage> coverages = [
    InsuranceCoverage(
      id: 'cov-001',
      insuranceId: 'ins-001', // Mercantil
      maxLimit: 50000.0,
      pharmacyPercentage: 0.70, // 70% cobertura
      ambulancePercentage: 1.0, // 100% cobertura
      laboratoryPercentage: 0.80,
      erConsultationPercentage: 0.90,
    ),
    InsuranceCoverage(
      id: 'cov-002',
      insuranceId: 'ins-003', // Plan Exclusivo
      maxLimit: 10000.0,
      pharmacyPercentage: 0.90, // Alta cobertura por ser exclusivo
      ambulancePercentage: 1.0,
      laboratoryPercentage: 0.90,
      erConsultationPercentage: 1.0,
    ),
  ];

  static final List<PatientPolicy> activePolicies = [
    PatientPolicy(
      id: 'pol-999',
      patientId: 'pat-123',
      insuranceId: 'ins-001',
      policyNumber: 'MC-2024-889900',
      status: PolicyStatus.active,
    ),
  ];
}
