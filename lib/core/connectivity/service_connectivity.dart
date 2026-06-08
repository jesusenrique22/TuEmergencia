import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../debug/realtime_debug_log.dart';
import '../network/api_url.dart';
import '../network/service_health_result.dart';

/// Comprobaciones HTTP centralizadas (API + gateway) con caché breve.
class ServiceConnectivity {
  ServiceConnectivity._();
  static final ServiceConnectivity instance = ServiceConnectivity._();

  static const _cacheTtl = Duration(seconds: 8);

  ServiceHealthResult? _apiCache;
  DateTime? _apiCacheAt;
  ServiceHealthResult? _gatewayCache;
  DateTime? _gatewayCacheAt;

  void invalidateCache() {
    _apiCache = null;
    _apiCacheAt = null;
    _gatewayCache = null;
    _gatewayCacheAt = null;
  }

  Future<bool> isApiReachable({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final r = await checkApiHealth(timeout: timeout);
    return r.reachable;
  }

  Future<bool> isGatewayReachable({
    Duration? timeout,
  }) async {
    final r = await checkGatewayHealth(timeout: timeout);
    return r.reachable;
  }

  Future<ServiceHealthResult> checkApiHealth({
    Duration timeout = const Duration(seconds: 5),
    bool useCache = true,
  }) async {
    if (useCache && _isFresh(_apiCacheAt) && _apiCache != null) {
      return _apiCache!;
    }
    final result = await _probe(
      ApiUrl.healthUri(),
      timeout: timeout,
      logTag: 'API',
      logLabel: 'Backend',
    );
    _apiCache = result;
    _apiCacheAt = DateTime.now();
    return result;
  }

  Future<ServiceHealthResult> checkGatewayHealth({
    Duration? timeout,
    bool useCache = true,
  }) async {
    final effectiveTimeout = timeout ??
        (ApiConfig.openedViaDevTunnel
            ? const Duration(seconds: 6)
            : const Duration(seconds: 4));
    if (useCache && _isFresh(_gatewayCacheAt) && _gatewayCache != null) {
      return _gatewayCache!;
    }
    final uri = Uri.parse(ApiConfig.gatewayHealthUrl);
    final result = await _probe(
      uri,
      timeout: effectiveTimeout,
      logTag: 'Health',
      logLabel: 'Gateway',
    );
    _gatewayCache = result;
    _gatewayCacheAt = DateTime.now();
    return result;
  }

  bool _isFresh(DateTime? at) {
    if (at == null) return false;
    return DateTime.now().difference(at) < _cacheTtl;
  }

  Future<ServiceHealthResult> _probe(
    Uri uri, {
    Duration timeout = const Duration(seconds: 5),
    required String logTag,
    required String logLabel,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final res = await http.get(uri).timeout(timeout);
      sw.stop();
      final ok = res.statusCode == 200 || res.statusCode == 304;
      final result = ServiceHealthResult(
        reachable: ok,
        uri: uri,
        statusCode: res.statusCode,
        responseBody: res.body,
        elapsed: sw.elapsed,
      );
      RealtimeDebugLog.instance.log(
        logTag,
        ok ? '$logLabel OK' : '$logLabel HTTP ${res.statusCode}',
        level: ok ? RealtimeDebugLevel.success : RealtimeDebugLevel.warn,
        detail: result.summary,
      );
      return result;
    } catch (e, st) {
      sw.stop();
      final result = ServiceHealthResult(
        reachable: false,
        uri: uri,
        error: e,
        elapsed: sw.elapsed,
      );
      RealtimeDebugLog.instance.log(
        logTag,
        '$logLabel no alcanzable',
        level: RealtimeDebugLevel.error,
        detail: '$e\n$st',
      );
      return result;
    }
  }
}
