import '../../../core/network/api_client.dart';

final _client = ApiClient();

class ChatConversationItem {
  final String id;
  final String doctorId;
  final String doctorName;
  final String? doctorAvatar;
  final String patientId;
  final String patientName;
  final String? patientAvatar;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const ChatConversationItem({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    this.doctorAvatar,
    required this.patientId,
    required this.patientName,
    this.patientAvatar,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ChatConversationItem.fromJson(Map<String, dynamic> j) {
    final doctor = j['doctorId'];
    final patient = j['patientId'];
    String idFrom(dynamic ref) {
      if (ref is Map) return ref['_id']?.toString() ?? '';
      return ref?.toString() ?? '';
    }
    String nameFrom(dynamic ref) {
      if (ref is Map) return ref['name'] as String? ?? '';
      return '';
    }
    String? picFrom(dynamic ref) {
      if (ref is Map) return ref['profilePic'] as String?;
      return null;
    }

    return ChatConversationItem(
      id: j['_id']?.toString() ?? '',
      doctorId: idFrom(doctor),
      doctorName: nameFrom(doctor),
      doctorAvatar: picFrom(doctor),
      patientId: idFrom(patient),
      patientName: nameFrom(patient),
      patientAvatar: picFrom(patient),
      lastMessage: j['lastMessage'] as String?,
      lastMessageAt: j['lastMessageAt'] != null
          ? DateTime.tryParse(j['lastMessageAt'] as String)
          : null,
    );
  }
}

class ChatMessageItem {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  const ChatMessageItem({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessageItem.fromJson(Map<String, dynamic> j) {
    final sender = j['senderId'];
    return ChatMessageItem(
      id: j['_id']?.toString() ?? '',
      senderId: sender is Map ? sender['_id']?.toString() ?? '' : '',
      senderName: sender is Map ? sender['name'] as String? ?? '' : '',
      text: j['text'] as String? ?? '',
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class ChatApiService {
  Future<List<ChatConversationItem>> listConversations() async {
    final data = await _client.get('/api/chat/conversations', auth: true);
    return (data as List<dynamic>)
        .map((e) => ChatConversationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatConversationItem> getOrCreateConversation({
    String? doctorId,
    String? patientId,
  }) async {
    final body = <String, dynamic>{
      'doctorId': ?doctorId,
      'patientId': ?patientId,
    };
    final data = await _client.post('/api/chat/conversations', body, auth: true);
    return ChatConversationItem.fromJson(data);
  }

  Future<List<ChatMessageItem>> getMessages(String conversationId) async {
    final data = await _client.get(
      '/api/chat/conversations/$conversationId/messages',
      auth: true,
    );
    return (data as List<dynamic>)
        .map((e) => ChatMessageItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessageItem> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final data = await _client.post(
      '/api/chat/messages',
      {'conversationId': conversationId, 'text': text},
      auth: true,
    );
    return ChatMessageItem.fromJson(data);
  }
}
