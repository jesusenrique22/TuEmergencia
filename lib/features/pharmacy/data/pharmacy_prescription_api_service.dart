import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/app_session.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/api_url.dart';
import '../domain/models/prescription_explanation.dart';
import '../domain/models/prescription_search_result.dart';

/// API: POST /api/pharmacy/prescription/search
/// Gemini solo en backend (1 llamada por foto); inventario en PostgreSQL.
class PharmacyPrescriptionApiService {
  static const _searchTimeout = Duration(seconds: 60);

  Future<PrescriptionSearchResult> searchByXFile(XFile image) async {
    final bytes = await image.readAsBytes();
    return searchByImageBytes(
      bytes,
      mimeType: _mimeFromName(image.mimeType, image.name),
    );
  }

  Future<PrescriptionSearchResult> searchByImageBytes(
    List<int> bytes, {
    String mimeType = 'image/jpeg',
  }) async {
    final base64Image = base64Encode(bytes);

    double? lat;
    double? lng;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    return _postSearch(
      imageBase64: base64Image,
      mimeType: mimeType,
      lat: lat,
      lng: lng,
    );
  }

  Future<PrescriptionSearchResult> searchByMedicationNames(
    List<String> medications, {
    double? lat,
    double? lng,
  }) {
    return _postSearch(medications: medications, lat: lat, lng: lng);
  }

  Future<PrescriptionSearchResult> _postSearch({
    String? imageBase64,
    String? mimeType,
    List<String>? medications,
    double? lat,
    double? lng,
  }) async {
    final token = AppSession.token;
    if (token == null || token.isEmpty) {
      throw Exception('Inicia sesión para buscar medicamentos en farmacias.');
    }

    final body = <String, dynamic>{};
    if (imageBase64 != null) {
      body['imageBase64'] = imageBase64;
      body['mimeType'] = mimeType ?? 'image/jpeg';
    }
    if (medications != null && medications.isNotEmpty) {
      body['medications'] = medications;
    }
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;

    final uri = Uri.parse(ApiUrl.resolve('/api/pharmacy/prescription/search'));
    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(_searchTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return PrescriptionSearchResult.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      String message = 'Error del servidor (${response.statusCode})';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        message = err['error'] as String? ?? message;
      } catch (_) {}
      if (response.statusCode == 401) {
        throw Exception('Tu sesión expiró. Cierra sesión e inicia de nuevo.');
      }
      throw Exception(message);
    } catch (e) {
      final text = e.toString();
      if (text.contains('TimeoutException') ||
          text.contains('SocketException') ||
          text.contains('ClientException') ||
          text.contains('Failed to fetch') ||
          text.contains('Connection refused')) {
        throw Exception(
          'No se pudo conectar al servidor (${ApiConfig.baseUrl}). '
          'Verifica que el backend esté corriendo: cd backend && pnpm run dev',
        );
      }
      if (e is Exception) rethrow;
      throw Exception(text.replaceFirst('Exception: ', ''));
    }
  }

  Future<PrescriptionExplanation> explainByXFile(XFile image) async {
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);
    final token = AppSession.token;
    if (token == null || token.isEmpty) {
      throw Exception('Inicia sesión para analizar tu receta.');
    }

    final body = {
      'imageBase64': base64Image,
      'mimeType': _mimeFromName(image.mimeType, image.name),
    };

    final uri = Uri.parse(ApiUrl.resolve('/api/pharmacy/prescription/explain'));
    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return PrescriptionExplanation.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      String message = 'Error del servidor (${response.statusCode})';
      try {
        final err = jsonDecode(response.body) as Map<String, dynamic>;
        message = err['error'] as String? ?? message;
      } catch (_) {}
      if (response.statusCode == 401) {
        throw Exception('Tu sesión expiró. Cierra sesión e inicia de nuevo.');
      }
      throw Exception(message);
    } catch (e) {
      final text = e.toString();
      if (text.contains('TimeoutException') ||
          text.contains('SocketException') ||
          text.contains('ClientException') ||
          text.contains('Failed to fetch') ||
          text.contains('Connection refused')) {
        throw Exception(
          'No se pudo conectar al servidor (${ApiConfig.baseUrl}). '
          'Verifica que el backend esté corriendo: cd backend && pnpm run dev',
        );
      }
      if (e is Exception) rethrow;
      throw Exception(text.replaceFirst('Exception: ', ''));
    }
  }

  String _mimeFromName(String? mimeType, String name) {
    if (mimeType != null && mimeType.isNotEmpty) return mimeType;
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
