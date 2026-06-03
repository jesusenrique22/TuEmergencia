import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../medical_history/data/medical_history_api_service.dart';

final _client = ApiClient();

enum ChatMessageKind { chat, clinical }

ChatMessageKind _kindFrom(dynamic value) {
  if (value == 'clinical') return ChatMessageKind.clinical;
  return ChatMessageKind.chat;
}

class ChatContactItem {
  final String id;
  final String name;
  final String? profilePic;
  final String role;

  const ChatContactItem({
    required this.id,
    required this.name,
    this.profilePic,
    required this.role,
  });

  factory ChatContactItem.fromJson(Map<String, dynamic> j) {
    return ChatContactItem(
      id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
      name: j['name'] as String? ?? '',
      profilePic: j['profilePic'] as String?,
      role: j['role'] as String? ?? '',
    );
  }
}

class ChatConversationItem {
  final String id;
  final String doctorId;
  final String doctorName;
  final String? doctorAvatar;
  final String patientId;
  final String patientName;
  final String? patientAvatar;
  final String? lastChatMessage;
  final DateTime? lastChatMessageAt;
  final String? lastClinicalMessage;
  final DateTime? lastClinicalMessageAt;

  const ChatConversationItem({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    this.doctorAvatar,
    required this.patientId,
    required this.patientName,
    this.patientAvatar,
    this.lastChatMessage,
    this.lastChatMessageAt,
    this.lastClinicalMessage,
    this.lastClinicalMessageAt,
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

    final legacyMessage = j['lastMessage'] as String?;
    final legacyAt = j['lastMessageAt'] != null
        ? DateTime.tryParse(j['lastMessageAt'] as String)
        : null;

    return ChatConversationItem(
      id: j['_id']?.toString() ?? '',
      doctorId: idFrom(doctor),
      doctorName: nameFrom(doctor),
      doctorAvatar: picFrom(doctor),
      patientId: idFrom(patient),
      patientName: nameFrom(patient),
      patientAvatar: picFrom(patient),
      lastChatMessage: j['lastChatMessage'] as String? ?? legacyMessage,
      lastChatMessageAt: j['lastChatMessageAt'] != null
          ? DateTime.tryParse(j['lastChatMessageAt'] as String)
          : legacyAt,
      lastClinicalMessage: j['lastClinicalMessage'] as String?,
      lastClinicalMessageAt: j['lastClinicalMessageAt'] != null
          ? DateTime.tryParse(j['lastClinicalMessageAt'] as String)
          : null,
    );
  }
}

class ChatMessageItem {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String? imageUrl;
  final ChatMessageKind kind;
  final DateTime createdAt;
  final String? doctorName;
  final String? patientName;

  const ChatMessageItem({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    this.kind = ChatMessageKind.chat,
    required this.createdAt,
    this.doctorName,
    this.patientName,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory ChatMessageItem.fromJson(Map<String, dynamic> j) {
    final sender = j['senderId'];
    String senderId = '';
    String senderName = '';
    if (sender is Map) {
      senderId = sender['_id']?.toString() ?? '';
      senderName = sender['name'] as String? ?? '';
    } else if (sender != null) {
      senderId = sender.toString();
    }

    String? doctorName;
    String? patientName;
    final conv = j['conversationId'];
    if (conv is Map) {
      final doc = conv['doctorId'];
      final pat = conv['patientId'];
      if (doc is Map) doctorName = doc['name'] as String?;
      if (pat is Map) patientName = pat['name'] as String?;
    }

    return ChatMessageItem(
      id: j['_id']?.toString() ?? '',
      senderId: senderId,
      senderName: senderName,
      text: j['text'] as String? ?? '',
      imageUrl: j['imageUrl'] as String?,
      kind: _kindFrom(j['kind']),
      createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
          DateTime.now(),
      doctorName: doctorName,
      patientName: patientName,
    );
  }
}

class ClinicalFeedItem {
  final String id;
  final String title;
  final String body;
  final String doctorName;
  final DateTime date;
  final bool isHistoryEntry;

  const ClinicalFeedItem({
    required this.id,
    required this.title,
    required this.body,
    required this.doctorName,
    required this.date,
    this.isHistoryEntry = false,
  });
}

class ChatApiService {
  Future<List<ChatConversationItem>> listConversations() async {
    final data = await _client.get('/api/chat/conversations', auth: true);
    return (data as List<dynamic>)
        .map((e) => ChatConversationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Contactos con cita para iniciar un chat nuevo (sin conversación previa).
  Future<List<ChatContactItem>> listContactsForNewChat() async {
    final data = await _client.get(
      '/api/chat/contacts?forNew=true',
      auth: true,
    );
    return (data as List<dynamic>)
        .map((e) => ChatContactItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessageItem>> getClinicalFeed() async {
    final data = await _client.get('/api/chat/clinical-feed', auth: true);
    return (data as List<dynamic>)
        .map((e) => ChatMessageItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Mensajes clínicos + entradas del historial médico (solo paciente).
  Future<List<ClinicalFeedItem>> getPatientClinicalTimeline() async {
    final messages = await getClinicalFeed();
    final history = MedicalHistoryApiService();
    final record = await history.getMyHistory();

    final items = <ClinicalFeedItem>[
      ...messages.map(
        (m) => ClinicalFeedItem(
          id: m.id,
          title: 'Mensaje del médico',
          body: m.text,
          doctorName: m.doctorName ?? m.senderName,
          date: m.createdAt,
        ),
      ),
      ...record.entries.map(
        (e) => ClinicalFeedItem(
          id: e.id,
          title: e.title,
          body: [
            if (e.description.isNotEmpty) e.description,
            if (e.diagnosis != null && e.diagnosis!.isNotEmpty)
              'Diagnóstico: ${e.diagnosis}',
            if (e.treatment != null && e.treatment!.isNotEmpty)
              'Tratamiento: ${e.treatment}',
          ].join('\n'),
          doctorName: e.doctorName,
          date: e.date,
          isHistoryEntry: true,
        ),
      ),
    ];
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
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

  Future<List<ChatMessageItem>> getMessages(
    String conversationId, {
    ChatMessageKind kind = ChatMessageKind.chat,
  }) async {
    final kindParam = kind == ChatMessageKind.clinical ? 'clinical' : 'chat';
    final data = await _client.get(
      '/api/chat/conversations/$conversationId/messages?kind=$kindParam',
      auth: true,
    );
    return (data as List<dynamic>)
        .map((e) => ChatMessageItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessageItem> sendMessage({
    required String conversationId,
    String text = '',
    ChatMessageKind kind = ChatMessageKind.chat,
    List<int>? imageBytes,
    String? imageMimeType,
  }) async {
    final body = <String, dynamic>{
      'conversationId': conversationId,
      'text': text,
      'kind': kind == ChatMessageKind.clinical ? 'clinical' : 'chat',
    };
    if (imageBytes != null && imageBytes.isNotEmpty) {
      body['imageBase64'] = base64Encode(imageBytes);
      body['mimeType'] = imageMimeType ?? 'image/jpeg';
    }
    final data = await _client.post('/api/chat/messages', body, auth: true);
    return ChatMessageItem.fromJson(data);
  }
}
