import '../connectivity/service_connectivity.dart';
import 'service_health_result.dart';

export 'service_health_result.dart' show GatewayHealthResult, ServiceHealthResult;

/// Comprueba si el gateway WebSocket responde (GET gatewayHealthUrl).
Future<bool> isGatewayReachable({
  Duration? timeout,
}) =>
    ServiceConnectivity.instance.isGatewayReachable(timeout: timeout);

Future<GatewayHealthResult> checkGatewayHealthDetailed({
  Duration timeout = const Duration(seconds: 5),
}) =>
    ServiceConnectivity.instance.checkGatewayHealth(timeout: timeout);
