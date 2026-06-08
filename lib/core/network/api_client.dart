import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../auth/app_session.dart';
import '../config/api_config.dart';
import '../connectivity/service_connectivity.dart';
import 'api_url.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Cliente HTTP compartido para toda la app (singleton).
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  factory ApiClient() => instance;

  static const connectionCooldown = Duration(seconds: 2);
  /// Por intento; con reintentos el fallo total es ~3× más rápido que antes (45s fijos).
  static const requestTimeout = Duration(seconds: 8);
  static const _maxAttempts = 3;
  static const _retryDelay = Duration(milliseconds: 350);
  static final Map<String, DateTime> _connectionFailuresByHost = {};

  static bool isInConnectionCooldownFor(String baseUrl) {
    final host = Uri.parse(baseUrl).host;
    final last = _connectionFailuresByHost[host];
    if (last == null) return false;
    return DateTime.now().difference(last) < connectionCooldown;
  }

  Uri _uri(String path) => Uri.parse(ApiUrl.resolve(path));

  void _ensureNotInCooldown() {
    if (isInConnectionCooldownFor(ApiConfig.baseUrl)) {
      throw ApiException(
        'Sin conexión al servidor (${ApiConfig.baseUrl}). '
        'Inicia: cd backend && pnpm run dev',
      );
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      if (attempt == 1) {
        _ensureNotInCooldown();
      } else {
        ServiceConnectivity.instance.invalidateCache();
        await Future<void>.delayed(_retryDelay);
      }
      try {
        final response = await request().timeout(
          requestTimeout,
          onTimeout: () {
            throw TimeoutException(
              'La API no respondió en ${requestTimeout.inSeconds}s (${ApiConfig.baseUrl})',
            );
          },
        );
        final host = Uri.parse(ApiConfig.baseUrl).host;
        _connectionFailuresByHost.remove(host);
        ServiceConnectivity.instance.invalidateCache();
        return response;
      } on TimeoutException catch (e) {
        lastError = e;
        if (attempt < _maxAttempts) continue;
        _markConnectionFailure();
        rethrow;
      } on http.ClientException catch (e) {
        lastError = e;
        if (attempt < _maxAttempts) continue;
        _markConnectionFailure();
        rethrow;
      }
    }
    throw lastError ?? StateError('API request failed');
  }

  void _markConnectionFailure() {
    final host = Uri.parse(ApiConfig.baseUrl).host;
    _connectionFailuresByHost[host] = DateTime.now();
    if (kDebugMode) {
      debugPrint(
        'API no disponible en ${ApiConfig.baseUrl}. Ejecuta: cd backend && pnpm run dev',
      );
    }
  }

  ApiException _connectionError([Object? cause]) => ApiException(
        cause is TimeoutException
            ? '${cause.message}. Comprueba cd backend && pnpm run dev y recarga el túnel (Cmd+Shift+R).'
            : 'No se pudo conectar al servidor (${ApiConfig.baseUrl}). '
                'Inicia: cd backend && pnpm run dev',
      );

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
    try {
      final response = await _send(
        () => http.get(_uri(path), headers: _headers(auth: auth)),
      );
      return _parseResponse(response, auth: auth);
    } on TimeoutException catch (e) {
      throw _connectionError(e);
    } on http.ClientException {
      throw _connectionError();
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    try {
      final response = await _send(
        () => http.post(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body),
        ),
      );
      return _parseResponse(response, auth: auth) as Map<String, dynamic>;
    } on TimeoutException catch (e) {
      throw _connectionError(e);
    } on http.ClientException {
      throw _connectionError();
    }
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final response = await _send(
        () => http.put(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body),
        ),
      );
      return _parseResponse(response, auth: auth) as Map<String, dynamic>;
    } on TimeoutException catch (e) {
      throw _connectionError(e);
    } on http.ClientException {
      throw _connectionError();
    }
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final response = await _send(
        () => http.patch(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body),
        ),
      );
      return _parseResponse(response, auth: auth) as Map<String, dynamic>;
    } on TimeoutException catch (e) {
      throw _connectionError(e);
    } on http.ClientException {
      throw _connectionError();
    }
  }

  Future<void> delete(String path, {bool auth = true}) async {
    try {
      final response = await _send(
        () => http.delete(_uri(path), headers: _headers(auth: auth)),
      );
      _parseResponse(response, auth: auth);
    } on TimeoutException catch (e) {
      throw _connectionError(e);
    } on http.ClientException {
      throw _connectionError();
    }
  }

  dynamic _parseResponse(http.Response response, {required bool auth}) {
    dynamic data;
    if (response.body.isNotEmpty) {
      data = jsonDecode(response.body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data ?? <String, dynamic>{};
    }

    if (response.statusCode == 401 && auth) {
      throw const ApiException(
        'Sesión inválida o expirada. Cierra sesión e inicia de nuevo.',
        statusCode: 401,
      );
    }

    final errorMap = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final message =
        errorMap['error'] as String? ??
        'Error del servidor (${response.statusCode})';
    throw ApiException(message, statusCode: response.statusCode);
  }
}
