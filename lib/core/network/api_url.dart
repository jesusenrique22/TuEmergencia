import '../config/api_config.dart';

/// Resuelve rutas relativas contra la API REST (evita duplicar join de URLs).
abstract final class ApiUrl {
  static String resolve(String path, {String? baseUrl}) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/+$'), '');
    final normalized = path.startsWith('/') ? path : '/$path';
    return '$base$normalized';
  }

  static Uri healthUri({String? baseUrl}) =>
      Uri.parse(resolve('/health', baseUrl: baseUrl));
}
