import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/app_session.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _headers({bool auth = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final sessionToken = AppSession.token;
      if (sessionToken == null || sessionToken.isEmpty) {
        throw const ApiException(
          'Sesión expirada. Inicia sesión de nuevo.',
          statusCode: 401,
        );
      }
      headers['Authorization'] = 'Bearer $sessionToken';
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool auth = true}) async {
    final response = await http.get(
      _uri(path),
      headers: _headers(auth: auth),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final response = await http.post(
      _uri(path),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await http.put(
      _uri(path),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await http.patch(
      _uri(path),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _parseResponse(response) as Map<String, dynamic>;
  }

  Future<void> delete(String path, {bool auth = true}) async {
    final response = await http.delete(
      _uri(path),
      headers: _headers(auth: auth),
    );
    _parseResponse(response);
  }

  dynamic _parseResponse(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      data = jsonDecode(response.body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data ?? <String, dynamic>{};
    }

    final errorMap = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final message =
        errorMap['error'] as String? ??
        'Error del servidor (${response.statusCode})';
    throw ApiException(message, statusCode: response.statusCode);
  }
}
