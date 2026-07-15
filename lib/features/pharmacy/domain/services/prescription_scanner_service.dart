import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/pharmacy_prescription_api_service.dart';
import '../models/prescription_search_result.dart';

/// Escaneo de recetas → backend (Gemini opcional + inventario en BD).
class PrescriptionScannerService {
  final PharmacyPrescriptionApiService _api = PharmacyPrescriptionApiService();

  Future<PrescriptionSearchResult> searchFromXFile(XFile image) {
    return _api.searchByXFile(image);
  }

  Future<PrescriptionSearchResult> searchFromMedicationNames(
    List<String> names,
  ) {
    return _api.searchByMedicationNames(names);
  }

  /// Fallback local si la API no está disponible (dev sin backend).
  Future<PrescriptionSearchResult> searchLocalDemo(List<String> names) async {
    if (kDebugMode) {
      debugPrint('[PrescriptionScanner] fallback demo local');
    }
    await Future.delayed(const Duration(milliseconds: 600));
    return _api.searchByMedicationNames(names);
  }

  void dispose() {}
}
