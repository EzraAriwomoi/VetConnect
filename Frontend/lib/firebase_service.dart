import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Authentication methods
  static Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Chat methods
  static Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? imageUrl,
  }) async {
    // Create chat room ID (sorted to ensure consistency)
    final List<String> ids = [senderId, receiverId];
    ids.sort();
    final String chatRoomId = ids.join('_');

    // Message data
    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    // Add message to chat room
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    // Update chat room metadata
    await _firestore.collection('chatRooms').doc(chatRoomId).set({
      'participants': [senderId, receiverId],
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    // Create chat room ID (sorted to ensure consistency)
    final List<String> ids = [userId, otherUserId];
    ids.sort();
    final String chatRoomId = ids.join('_');

    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  static Stream<QuerySnapshot> getChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .snapshots();
  }

  static Future<void> markMessagesAsRead(String userId, String otherUserId) async {
    // Create chat room ID
    final List<String> ids = [userId, otherUserId];
    ids.sort();
    final String chatRoomId = ids.join('_');

    // Get unread messages
    final querySnapshot = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    // Mark messages as read
    final WriteBatch batch = _firestore.batch();
    querySnapshot.docs.forEach((doc) {
      batch.update(doc.reference, {'isRead': true});
    });

    // Reset unread count
    batch.update(
      _firestore.collection('chatRooms').doc(chatRoomId),
      {'unreadCount': 0},
    );

    await batch.commit();
  }

  // Message count methods for payment feature
  static Future<int> getMessageCount(String userId, String vetId) async {
    final List<String> ids = [userId, vetId];
    ids.sort();
    ids.join('_');

    try {
      final snapshot = await _firestore
          .collection('messageCount')
          .doc(userId)
          .collection('vets')
          .doc(vetId)
          .get();

      if (snapshot.exists) {
        return snapshot.data()?['count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error getting message count: $e');
      return 0;
    }
  }

  static Future<void> incrementMessageCount(String userId, String vetId) async {
    await _firestore
        .collection('messageCount')
        .doc(userId)
        .collection('vets')
        .doc(vetId)
        .set({
      'count': FieldValue.increment(1),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> resetMessageCount(String userId, String vetId) async {
    await _firestore
        .collection('messageCount')
        .doc(userId)
        .collection('vets')
        .doc(vetId)
        .set({
      'count': 0,
      'lastUpdated': FieldValue.serverTimestamp(),
      'paymentHistory': FieldValue.arrayUnion([
        {
          'date': Timestamp.now(),
          'amount': 'One-time consultation',
        }
      ]),
    }, SetOptions(merge: true));
  }

  // Reviews methods
  static Future<void> addReview({
    required String vetId,
    required String userId,
    required String userName,
    required String reviewText,
    required double rating,
  }) async {
    final reviewData = {
      'userId': userId,
      'userName': userName,
      'reviewText': reviewText,
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
      'replies': [],
    };

    await _firestore
        .collection('vetProfiles')
        .doc(vetId)
        .collection('reviews')
        .add(reviewData);

    // Update average rating
    final reviewsSnapshot = await _firestore
        .collection('vetProfiles')
        .doc(vetId)
        .collection('reviews')
        .get();

    double totalRating = 0;
    reviewsSnapshot.docs.forEach((doc) {
      totalRating += doc.data()['rating'] as double;
    });

    double averageRating = totalRating / reviewsSnapshot.docs.length;

    await _firestore.collection('vetProfiles').doc(vetId).set({
      'averageRating': averageRating,
      'reviewCount': reviewsSnapshot.docs.length,
    }, SetOptions(merge: true));
  }

  static Future<void> addReplyToReview({
    required String vetId,
    required String reviewId,
    required String userId,
    required String userName,
    required String replyText,
  }) async {
    final replyData = {
      'userId': userId,
      'userName': userName,
      'replyText': replyText,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('vetProfiles')
        .doc(vetId)
        .collection('reviews')
        .doc(reviewId)
        .update({
      'replies': FieldValue.arrayUnion([replyData]),
    });
  }

  static Stream<QuerySnapshot> getReviews(String vetId) {
    return _firestore
        .collection('vetProfiles')
        .doc(vetId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Help desk methods
  static Future<void> addHelpDeskPost({
    required String userId,
    required String userName,
    required String title,
    required String content,
    required String animalType,
    String? imageUrl,
  }) async {
    final postData = {
      'userId': userId,
      'userName': userName,
      'title': title,
      'content': content,
      'animalType': animalType,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'comments': [],
      'likes': 0,
    };

    await _firestore.collection('helpDesk').add(postData);
  }

  static Future<void> addCommentToHelpDesk({
    required String postId,
    required String userId,
    required String userName,
    required String comment,
  }) async {
    final commentData = {
      'userId': userId,
      'userName': userName,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('helpDesk').doc(postId).update({
      'comments': FieldValue.arrayUnion([commentData]),
    });
  }

  static Stream<QuerySnapshot> getHelpDeskPosts() {
    return _firestore
        .collection('helpDesk')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Notifications
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    final notificationData = {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,  // appointment, message, review, etc.
      'relatedId': relatedId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(notificationData);
  }

  static Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> markNotificationAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Clinic location methods
  static Future<void> updateClinicLocation({
    required String vetId,
    required double latitude,
    required double longitude,
    required String clinicName,
    required String address,
  }) async {
    await _firestore.collection('vetProfiles').doc(vetId).update({
      'clinic': {
        'name': clinicName,
        'address': address,
        'location': GeoPoint(latitude, longitude),
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getNearbyVetClinics() async {
    final snapshot = await _firestore.collection('vetProfiles').get();
    
    List<Map<String, dynamic>> clinics = [];
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('clinic') && data['clinic'] != null) {
        final clinic = data['clinic'];
        if (clinic.containsKey('location')) {
          clinics.add({
            'id': doc.id,
            'name': clinic['name'] ?? 'Unknown Clinic',
            'address': clinic['address'] ?? 'No address',
            'latitude': clinic['location'].latitude,
            'longitude': clinic['location'].longitude,
            'vetName': data['fullName'] ?? 'Unknown Vet',
          });
        }
      }
    }
    
    return clinics;
  }
}
