class HelpDeskComment {
  final String id;
  final String userId;
  final String userName;
  final String comment;
  final DateTime timestamp;

  HelpDeskComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.timestamp,
  });

  factory HelpDeskComment.fromJson(Map<String, dynamic> json) {
    return HelpDeskComment(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      comment: json['comment'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class HelpDeskPost {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String content;
  final String animalType;
  final String? imageUrl;
  final DateTime timestamp;
  final List<HelpDeskComment> comments;
  final int likes;

  HelpDeskPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.content,
    required this.animalType,
    this.imageUrl,
    required this.timestamp,
    required this.comments,
    required this.likes,
  });

  factory HelpDeskPost.fromJson(Map<String, dynamic> json) {
    List<HelpDeskComment> commentList = [];
    if (json.containsKey('comments') && json['comments'] is List) {
      commentList = (json['comments'] as List)
          .map((commentJson) => HelpDeskComment.fromJson(commentJson))
          .toList();
    }
    
    return HelpDeskPost(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      title: json['title'],
      content: json['content'],
      animalType: json['animal_type'],
      imageUrl: json['image_url'],
      timestamp: DateTime.parse(json['timestamp']),
      comments: commentList,
      likes: json['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'title': title,
      'content': content,
      'animal_type': animalType,
      'image_url': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'likes': likes,
    };
  }
}
