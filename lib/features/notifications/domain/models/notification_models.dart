enum NotificationType { info, success, warning, alert }

enum NotificationCategory {
  appointmentReminder,
  chatMessage,
  clinicInvitation,
  system,
  unknown,
}

class AppNotification {
  final String id;
  final String userId; // El ID del destinatario (paciente, admin, médico, etc.)
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;
  final String? relatedPath;
  final String? relatedId;
  final NotificationCategory category;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.relatedPath,
    this.relatedId,
    this.category = NotificationCategory.unknown,
  });

  bool get isPendingClinicInvitation =>
      category == NotificationCategory.clinicInvitation &&
      title == 'Invitación a clínica' &&
      relatedId != null &&
      relatedId!.isNotEmpty;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final rawType = map['type']?.toString().toUpperCase() ?? 'INFO';
    final type = switch (rawType) {
      'SUCCESS' => NotificationType.success,
      'WARNING' => NotificationType.warning,
      'ALERT' => NotificationType.alert,
      _ => NotificationType.info,
    };
    final rawCreatedAt = map['createdAt'];
    final rawCategory = map['category']?.toString().toUpperCase() ?? '';
    final category = switch (rawCategory) {
      'APPOINTMENT_REMINDER' => NotificationCategory.appointmentReminder,
      'CHAT_MESSAGE' => NotificationCategory.chatMessage,
      'CLINIC_INVITATION' => NotificationCategory.clinicInvitation,
      'SYSTEM' => NotificationCategory.system,
      _ => NotificationCategory.unknown,
    };

    return AppNotification(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: type,
      createdAt: rawCreatedAt is DateTime
          ? rawCreatedAt
          : DateTime.tryParse(rawCreatedAt?.toString() ?? '') ?? DateTime.now(),
      isRead: map['isRead'] == true,
      relatedPath: map['relatedPath']?.toString(),
      relatedId: map['relatedId']?.toString(),
      category: category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'createdAt': createdAt,
      'isRead': isRead,
      'relatedPath': relatedPath,
      'relatedId': relatedId,
    };
  }
}
