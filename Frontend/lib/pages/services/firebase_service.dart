import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send Message
  Future<void> sendMessage(String receiverId, String message) async {
    final user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('chats').add({
        'senderId': user.uid,
        'receiverId': receiverId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get Messages Stream
  Stream<QuerySnapshot> getMessages(String receiverId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();

    return _firestore
        .collection('chats')
        .where('senderId', isEqualTo: user.uid)
        .where('receiverId', isEqualTo: receiverId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
