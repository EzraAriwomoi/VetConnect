class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.timestamp,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      relatedId: json['related_id'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'related_id': relatedId,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
    };
  }
}
