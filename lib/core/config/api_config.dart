import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'service_ports.dart';

class ApiConfig {
  static String? _env(String key) {
    if (!dotenv.isInitialized) return null;
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// True si la app web se abrió desde un Dev Tunnel (Cursor/VS Code), no localhost.
  static bool get openedViaDevTunnel {
    if (!kIsWeb) return false;
    final host = Uri.base.host.toLowerCase();
    return host.contains('devtunnels.ms') ||
        host.contains('github.dev') ||
        host.contains('githubpreview.dev');
  }

  /// Deriva URL del túnel para otro puerto: `…-8088….devtunnels.ms` → `…-3000….devtunnels.ms`
  static String? devTunnelUrlForPort(int port) {
    if (!openedViaDevTunnel) return null;
    final uri = Uri.base;
    final match = RegExp(r'^(.+)-(\d+)\.(.+)$').firstMatch(uri.host);
    if (match == null) return null;
    return '${uri.scheme}://${match.group(1)}-$port.${match.group(3)}';
  }

  static String get baseUrl {
    if (openedViaDevTunnel) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty) return origin;
      final public = _env('PUBLIC_API_URL');
      if (public != null) return public;
      final tunnelApi = devTunnelUrlForPort(ServicePorts.api);
      if (tunnelApi != null) return tunnelApi;
    }
    return _alignUrlForDevice(
      _readUrl('API_BASE_URL', 'http://localhost:${ServicePorts.api}'),
    );
  }

  /// GET /gateway-health (proxy en :8088) o /health en :3001.
  static String get gatewayHealthUrl {
    if (openedViaDevTunnel) {
      return '${Uri.base.origin}/gateway-health';
    }
    return '$socketUrl/health';
  }

  /// Gateway Socket.IO — en Dev Tunnel mismo origen :8088 (proxy /socket.io).
  static String get socketUrl {
    if (openedViaDevTunnel) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty) return origin;
      final public = _env('PUBLIC_SOCKET_URL');
      if (public != null) return public;
      final tunnelSocket = devTunnelUrlForPort(ServicePorts.realtime);
      if (tunnelSocket != null) return tunnelSocket;
    }

    final fromEnv = _env('SOCKET_URL');
    if (fromEnv != null) {
      return _alignUrlForDevice(fromEnv);
    }
    final api = _readUrl('API_BASE_URL', 'http://localhost:${ServicePorts.api}');
    final apiPort = ':${ServicePorts.api}';
    if (api.contains(apiPort)) {
      return _alignUrlForDevice(
        api.replaceFirst(apiPort, ':${ServicePorts.realtime}'),
      );
    }
    return _alignUrlForDevice('$api:${ServicePorts.realtime}');
  }

  static String _readUrl(String key, String fallback) {
    return _env(key) ?? fallback;
  }

  /// Puerto fijo del servidor Flutter web en LAN (ver `scripts/run-web-lan.sh`).
  static int get flutterWebPort {
    return int.tryParse(_env('FLUTTER_WEB_PORT') ?? '') ?? ServicePorts.flutterWeb;
  }

  /// IP/host del Mac en Wi‑Fi para probar desde otro dispositivo (`.env` → DEV_HOST).
  static String? get devHost {
    return _env('DEV_HOST');
  }

  /// URL para abrir la app en móvil/tablet (misma Wi‑Fi). Requiere [devHost].
  static String? get lanWebAppUrl {
    final host = devHost;
    if (host == null) return null;
    return 'http://$host:$flutterWebPort';
  }

  /// Texto para panel debug / logs según cómo se abrió la app.
  static String get connectivityHint {
    if (openedViaDevTunnel) {
      return 'Dev Tunnel (${Uri.base.origin}, API/socket por proxy :8088)';
    }
    if (lanWebAppUrl != null) {
      return 'LAN: abre $lanWebAppUrl en otro dispositivo (misma Wi‑Fi)';
    }
    if (kIsWeb) {
      final page = webOriginLabel;
      final host = Uri.base.host;
      if (!_isLoopbackHost(host)) {
        return 'Web en $page → API/socket en $baseUrl (misma IP automática)';
      }
      return 'Web local ($page) → API en $baseUrl';
    }
    if (devHost != null) {
      return 'Móvil con DEV_HOST=$devHost → $baseUrl';
    }
    return 'Simulador/emulador en este Mac → $baseUrl (DEV_HOST solo para físico en Wi‑Fi)';
  }

  static bool _isLoopbackHost(String host) {
    final h = host.toLowerCase();
    return h == 'localhost' || h == '127.0.0.1' || h == '::1';
  }

  /// Alinea localhost/127.0.0.1 con la plataforma y el host desde el que se abrió la app.
  static String _alignUrlForDevice(String url) {
    final uri = Uri.parse(url);
    final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);

    final hostOverride = devHost;
    if (hostOverride != null && _isLoopbackHost(uri.host)) {
      return '${uri.scheme}://$hostOverride:$port';
    }

    if (kIsWeb) {
      final pageHost = Uri.base.host;
      // http://192.168.x.x:8088 → API en 192.168.x.x:3000 (sin DEV_HOST en .env)
      if (_isLoopbackHost(uri.host) && !_isLoopbackHost(pageHost)) {
        return uri.replace(host: pageHost).toString();
      }
      // localhost:62168 → localhost:3000 (evita mezclar localhost con 127.0.0.1 / CORS)
      if (_isLoopbackHost(uri.host) && _isLoopbackHost(pageHost)) {
        return uri.replace(host: pageHost).toString();
      }
      return url;
    }

    try {
      if (Platform.isAndroid) {
        final host = _isLoopbackHost(uri.host) ? '10.0.2.2' : uri.host;
        return uri.replace(host: host).toString();
      }
      if (Platform.isIOS) {
        final host = uri.host == 'localhost' ? '127.0.0.1' : uri.host;
        return uri.replace(host: host).toString();
      }
    } catch (_) {
      // Plataformas sin dart:io
    }
    return url;
  }

  /// STUN por defecto + TURN opcional vía [.env] (mejora audio/video entre redes).
  static List<Map<String, dynamic>> get webRtcIceServers {
    final servers = <Map<String, dynamic>>[
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ];
    final turnUrl = _env('WEBRTC_TURN_URL');
    if (turnUrl == null) return servers;

    final turn = <String, dynamic>{'urls': turnUrl};
    final username = _env('WEBRTC_TURN_USERNAME');
    final credential = _env('WEBRTC_TURN_CREDENTIAL');
    if (username != null && username.isNotEmpty) {
      turn['username'] = username;
      turn['credential'] = credential ?? '';
    }
    servers.add(turn);
    return servers;
  }

  static bool get hasTurnServer => _env('WEBRTC_TURN_URL') != null;

  /// Origen de la página web; [Uri.origin] solo admite http/https.
  static String get webOriginLabel {
    final base = Uri.base;
    if (base.scheme == 'http' || base.scheme == 'https') return base.origin;
    return base.toString();
  }

  /// Log útil al depurar simulador vs web (solo debug).
  static void logResolvedEndpoints() {
    if (!kDebugMode) return;
    debugPrint('[ApiConfig] API_BASE_URL → $baseUrl');
    debugPrint('[ApiConfig] SOCKET_URL   → $socketUrl');
    if (kIsWeb) debugPrint('[ApiConfig] Origen web   → $webOriginLabel');
    debugPrint('[ApiConfig] Conectividad → $connectivityHint');
    debugPrint('[ApiConfig] WebRTC TURN  → ${hasTurnServer ? "configurado" : "solo STUN"}');
  }
}
