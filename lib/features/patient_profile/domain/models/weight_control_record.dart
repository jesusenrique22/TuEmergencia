class WeightControlRecord {
  final String weightKg;
  final String fatPercent;
  final String visceral;
  final String muscleKg;
  final String bmi;
  final String doseDate;
  final String dose;

  const WeightControlRecord({
    this.weightKg = '',
    this.fatPercent = '',
    this.visceral = '',
    this.muscleKg = '',
    this.bmi = '',
    this.doseDate = '',
    this.dose = '',
  });

  factory WeightControlRecord.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    return WeightControlRecord(
      weightKg: s(json['weightKg']),
      fatPercent: s(json['fatPercent']),
      visceral: s(json['visceral']),
      muscleKg: s(json['muscleKg']),
      bmi: s(json['bmi']),
      doseDate: s(json['doseDate']),
      dose: s(json['dose']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (weightKg.isNotEmpty) 'weightKg': weightKg,
        if (fatPercent.isNotEmpty) 'fatPercent': fatPercent,
        if (visceral.isNotEmpty) 'visceral': visceral,
        if (muscleKg.isNotEmpty) 'muscleKg': muscleKg,
        if (bmi.isNotEmpty) 'bmi': bmi,
        if (doseDate.isNotEmpty) 'doseDate': doseDate,
        if (dose.isNotEmpty) 'dose': dose,
      };

  WeightControlRecord copyWith({
    String? weightKg,
    String? fatPercent,
    String? visceral,
    String? muscleKg,
    String? bmi,
    String? doseDate,
    String? dose,
  }) {
    return WeightControlRecord(
      weightKg: weightKg ?? this.weightKg,
      fatPercent: fatPercent ?? this.fatPercent,
      visceral: visceral ?? this.visceral,
      muscleKg: muscleKg ?? this.muscleKg,
      bmi: bmi ?? this.bmi,
      doseDate: doseDate ?? this.doseDate,
      dose: dose ?? this.dose,
    );
  }
}
