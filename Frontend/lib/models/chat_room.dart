class ChatRoom {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? otherUserImageUrl;

  ChatRoom({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.otherUserImageUrl,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      otherUserId: json['other_user_id'],
      otherUserName: json['other_user_name'],
      lastMessage: json['last_message'],
      lastMessageTime: DateTime.parse(json['last_message_time']),
      unreadCount: json['unread_count'] ?? 0,
      otherUserImageUrl: json['other_user_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count': unreadCount,
      'other_user_image_url': otherUserImageUrl,
    };
  }
}
