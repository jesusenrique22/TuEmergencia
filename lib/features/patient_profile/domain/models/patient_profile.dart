import 'weight_control_record.dart';

class PatientProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String documentId;
  final String birthDate;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String referredBy;
  final String maritalStatus;
  final String occupation;
  final String bloodType;
  final String allergies;
  final String chronicConditions;
  final String currentMedications;
  final String surgeries;
  final String weightKg;
  final String heightCm;
  final String obesityType;
  final String recommendedSurgery;
  final String vaccines;
  final bool hasHypertension;
  final bool hasDiabetes;
  final bool hasBronchialAsthma;
  final bool isSmoker;
  final String covidSeverity;
  final String observations;
  final List<WeightControlRecord> weightControls;
  final String insuranceProvider;
  final String policyNumber;
  final bool medicalHistoryCompleted;

  const PatientProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.documentId = '',
    this.birthDate = '',
    this.address = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.referredBy = '',
    this.maritalStatus = '',
    this.occupation = '',
    this.bloodType = 'O+',
    this.allergies = '',
    this.chronicConditions = '',
    this.currentMedications = '',
    this.surgeries = '',
    this.weightKg = '',
    this.heightCm = '',
    this.obesityType = '',
    this.recommendedSurgery = '',
    this.vaccines = '',
    this.hasHypertension = false,
    this.hasDiabetes = false,
    this.hasBronchialAsthma = false,
    this.isSmoker = false,
    this.covidSeverity = 'NONE',
    this.observations = '',
    this.weightControls = const [],
    this.insuranceProvider = '',
    this.policyNumber = '',
    this.medicalHistoryCompleted = false,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    String str(dynamic value) => value?.toString() ?? '';
    bool flag(dynamic value) => value == true;
    final userRef = json['userId'];
    final id = userRef is Map
        ? str(userRef['_id'] ?? userRef['id'])
        : str(json['_id'] ?? json['id'] ?? userRef);

    final controlsRaw = json['weightControls'];
    final controls = controlsRaw is List
        ? controlsRaw
            .whereType<Map>()
            .map((e) => WeightControlRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <WeightControlRecord>[];

    return PatientProfile(
      id: id,
      fullName: str(json['fullName']),
      email: str(json['email']),
      phone: str(json['phone']),
      documentId: str(json['documentId']),
      birthDate: str(json['birthDate']),
      address: str(json['address']),
      emergencyContactName: str(json['emergencyContactName']),
      emergencyContactPhone: str(json['emergencyContactPhone']),
      referredBy: str(json['referredBy']),
      maritalStatus: str(json['maritalStatus']),
      occupation: str(json['occupation']),
      bloodType: str(json['bloodType']).isEmpty ? 'O+' : str(json['bloodType']),
      allergies: str(json['allergies']),
      chronicConditions: str(json['chronicConditions']),
      currentMedications: str(json['currentMedications']),
      surgeries: str(json['surgeries']),
      weightKg: str(json['weightKg']),
      heightCm: str(json['heightCm']),
      obesityType: str(json['obesityType']),
      recommendedSurgery: str(json['recommendedSurgery']),
      vaccines: str(json['vaccines']),
      hasHypertension: flag(json['hasHypertension']),
      hasDiabetes: flag(json['hasDiabetes']),
      hasBronchialAsthma: flag(json['hasBronchialAsthma']),
      isSmoker: flag(json['isSmoker']),
      covidSeverity: str(json['covidSeverity']).isEmpty ? 'NONE' : str(json['covidSeverity']),
      observations: str(json['observations']),
      weightControls: controls,
      insuranceProvider: str(json['insuranceProvider']),
      policyNumber: str(json['policyNumber']),
      medicalHistoryCompleted: flag(json['medicalHistoryCompleted']),
    );
  }

  factory PatientProfile.fromUser({
    required String id,
    required String name,
    required String email,
    String? phone,
  }) {
    return PatientProfile(
      id: id,
      fullName: name,
      email: email,
      phone: phone ?? '',
    );
  }

  Map<String, dynamic> toApiJson({bool? markHistoryCompleted}) {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'documentId': documentId,
      'birthDate': birthDate,
      'address': address,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'referredBy': referredBy,
      'maritalStatus': maritalStatus,
      'occupation': occupation,
      'bloodType': bloodType,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'currentMedications': currentMedications,
      'surgeries': surgeries,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'obesityType': obesityType,
      'recommendedSurgery': recommendedSurgery,
      'vaccines': vaccines,
      'hasHypertension': hasHypertension,
      'hasDiabetes': hasDiabetes,
      'hasBronchialAsthma': hasBronchialAsthma,
      'isSmoker': isSmoker,
      'covidSeverity': covidSeverity,
      'observations': observations,
      'insuranceProvider': insuranceProvider,
      'policyNumber': policyNumber,
      'medicalHistoryCompleted':
          markHistoryCompleted ?? medicalHistoryCompleted,
    };
  }

  PatientProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? documentId,
    String? birthDate,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? referredBy,
    String? maritalStatus,
    String? occupation,
    String? bloodType,
    String? allergies,
    String? chronicConditions,
    String? currentMedications,
    String? surgeries,
    String? weightKg,
    String? heightCm,
    String? obesityType,
    String? recommendedSurgery,
    String? vaccines,
    bool? hasHypertension,
    bool? hasDiabetes,
    bool? hasBronchialAsthma,
    bool? isSmoker,
    String? covidSeverity,
    String? observations,
    List<WeightControlRecord>? weightControls,
    String? insuranceProvider,
    String? policyNumber,
    bool? medicalHistoryCompleted,
  }) {
    return PatientProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      documentId: documentId ?? this.documentId,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      referredBy: referredBy ?? this.referredBy,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      occupation: occupation ?? this.occupation,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      currentMedications: currentMedications ?? this.currentMedications,
      surgeries: surgeries ?? this.surgeries,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      obesityType: obesityType ?? this.obesityType,
      recommendedSurgery: recommendedSurgery ?? this.recommendedSurgery,
      vaccines: vaccines ?? this.vaccines,
      hasHypertension: hasHypertension ?? this.hasHypertension,
      hasDiabetes: hasDiabetes ?? this.hasDiabetes,
      hasBronchialAsthma: hasBronchialAsthma ?? this.hasBronchialAsthma,
      isSmoker: isSmoker ?? this.isSmoker,
      covidSeverity: covidSeverity ?? this.covidSeverity,
      observations: observations ?? this.observations,
      weightControls: weightControls ?? this.weightControls,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      policyNumber: policyNumber ?? this.policyNumber,
      medicalHistoryCompleted:
          medicalHistoryCompleted ?? this.medicalHistoryCompleted,
    );
  }
}
