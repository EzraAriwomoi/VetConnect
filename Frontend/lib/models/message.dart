import 'package:intl/intl.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;
  final String? senderName;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    required this.isRead,
    this.senderName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      imageUrl: json['image_url'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      senderName: json['sender_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'image_url': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'sender_name': senderName,
    };
  }

  String get formattedTime {
    return DateFormat('h:mm a').format(timestamp);
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}
