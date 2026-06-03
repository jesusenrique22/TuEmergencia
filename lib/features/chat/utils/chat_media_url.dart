import '../../../core/config/api_config.dart';

String chatMediaFullUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
  return '$base$path';
}
