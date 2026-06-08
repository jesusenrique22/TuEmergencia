class ServiceHealthResult {
  final bool reachable;
  final Uri uri;
  final int? statusCode;
  final String? responseBody;
  final Object? error;
  final Duration elapsed;

  const ServiceHealthResult({
    required this.reachable,
    required this.uri,
    this.statusCode,
    this.responseBody,
    this.error,
    this.elapsed = Duration.zero,
  });

  String get summary {
    if (reachable) {
      final body = responseBody ?? '';
      final preview =
          body.length > 100 ? '${body.substring(0, 100)}…' : body;
      return 'HTTP $statusCode en ${elapsed.inMilliseconds}ms — $preview';
    }
    return error?.toString() ?? 'Sin respuesta';
  }
}

/// Alias histórico (gateway).
typedef GatewayHealthResult = ServiceHealthResult;
