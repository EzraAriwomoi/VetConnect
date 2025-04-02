class Reply {
  final String id;
  final String userId;
  final String userName;
  final String replyText;
  final DateTime timestamp;

  Reply({
    required this.id,
    required this.userId,
    required this.userName,
    required this.replyText,
    required this.timestamp,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      replyText: json['reply_text'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'reply_text': replyText,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class Review {
  final String id;
  final String userId;
  final String userName;
  final String reviewText;
  final double rating;
  final DateTime timestamp;
  final List<Reply> replies;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.reviewText,
    required this.rating,
    required this.timestamp,
    required this.replies,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    List<Reply> replyList = [];
    if (json.containsKey('replies') && json['replies'] is List) {
      replyList = (json['replies'] as List)
          .map((replyJson) => Reply.fromJson(replyJson))
          .toList();
    }
    
    return Review(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      reviewText: json['review_text'],
      rating: json['rating'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      replies: replyList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'review_text': reviewText,
      'rating': rating,
      'timestamp': timestamp.toIso8601String(),
      'replies': replies.map((reply) => reply.toJson()).toList(),
    };
  }
}
