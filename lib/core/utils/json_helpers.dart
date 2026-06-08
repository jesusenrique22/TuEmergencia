/// Helpers compartidos para respuestas JSON del backend (Mongo-style `_id` o `id`).
class JsonHelpers {
  JsonHelpers._();

  static String idFromJson(Map<String, dynamic> json) =>
      (json['_id'] ?? json['id']).toString();

  static double? doubleFromJson(dynamic value) =>
      value == null ? null : (value as num).toDouble();

  static DateTime dateFromJson(dynamic value) {
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static Map<String, dynamic> asMap(dynamic data) =>
      Map<String, dynamic>.from(data as Map);
}
