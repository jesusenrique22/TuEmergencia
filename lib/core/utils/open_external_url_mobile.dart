import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalUrl(String url) async {
  if (url.isEmpty) return false;
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
