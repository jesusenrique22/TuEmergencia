import '../../../core/network/api_client.dart';
import '../domain/models/notification_models.dart';

final _client = ApiClient();

class NotificationsApiService {
  Future<List<AppNotification>> list() async {
    final data = await _client.get('/api/notifications', auth: true);
    final list = data as List<dynamic>;
    return list
        .map((e) => AppNotification.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final data = await _client.get('/api/notifications/unread-count', auth: true);
    final map = data as Map<String, dynamic>;
    return (map['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) async {
    await _client.patch('/api/notifications/$id/read', {}, auth: true);
  }

  Future<void> markAllRead() async {
    await _client.patch('/api/notifications/read-all', {}, auth: true);
  }
}
