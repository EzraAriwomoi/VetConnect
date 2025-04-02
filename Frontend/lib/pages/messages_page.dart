import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:vetconnect/pages/chat_screen.dart';
import 'package:vetconnect/pages/select_vet_page.dart';

class MessagesPage extends StatefulWidget {
  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isMigrating = false;

  @override
  void initState() {
    super.initState();
    // Run migration when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndMigrateChatRooms();
    });
  }

  String _getChatRoomId(String user1, String user2) {
    List<String> emails = {user1, user2}.toList()
      ..sort(); // Ensure sorted order
    return emails.join('_');
  }

  Future<void> createChatRoom(String vetEmail) async {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) return;

    // Generate consistent chat room ID
    final participants = [userEmail, vetEmail]..sort();
    final chatRoomId = participants.join('_');

    await _firestore.collection('chatRooms').doc(chatRoomId).set({
      'participantEmails': participants,
      'participants': {
        userEmail: true,
        vetEmail: true,
      },
      'vetEmail': vetEmail,
      'userEmail': userEmail,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Chat started',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': userEmail,
    }, SetOptions(merge: true));
  }

  Future<void> _checkAndMigrateChatRooms() async {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) return;

    setState(() => _isMigrating = true);

    try {
      // Check if any old format rooms exist
      final oldRooms = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: userEmail)
          .get();

      final hasOldRooms = oldRooms.docs.any((doc) => !doc.id.contains('_'));

      if (hasOldRooms) {
        await _migrateChatRooms();
      }
    } catch (e) {
      print("Migration error: $e");
    } finally {
      setState(() => _isMigrating = false);
    }
  }

  Future<void> _migrateChatRooms() async {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) return;

    final oldRooms = await _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userEmail)
        .get();

    for (var room in oldRooms.docs) {
      if (!room.id.contains('_')) {
        final participants = List<String>.from(room['participants']);
        if (participants.length != 2) continue;

        final newRoomId = _getChatRoomId(participants[0], participants[1]);

        // Check if new room already exists
        final newRoomExists =
            (await _firestore.collection('chatRooms').doc(newRoomId).get())
                .exists;

        if (!newRoomExists) {
          // Create new room with metadata
          await _firestore.collection('chatRooms').doc(newRoomId).set({
            'participants': participants,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Move messages
          final messages = await room.reference.collection('messages').get();
          final batch = _firestore.batch();

          for (var msg in messages.docs) {
            final newMsgRef = _firestore
                .collection('chatRooms')
                .doc(newRoomId)
                .collection('messages')
                .doc();

            batch.set(newMsgRef, msg.data());
          }
          await batch.commit();
        }

        // Delete old room
        await room.reference.delete();
      }
    }
  }

  Future<List<Map<String, dynamic>>> getChatPartners(String userEmail) async {
    final snapshot = await _firestore
        .collection('chatRooms')
        .where('participantEmails', arrayContains: userEmail)
        .get();

    return snapshot.docs.where((doc) {
      // Filter out malformed chats
      final participants = List<String>.from(doc['participantEmails'] ?? []);
      return participants.length == 2;
    }).map((doc) {
      final vetEmail = (doc['participantEmails'] as List)
          .firstWhere((email) => email != userEmail);

      return {
        'vetEmail': vetEmail,
        'chatRoomId': doc.id,
        'lastMessage': doc['lastMessage'] ?? 'No messages yet',
        'lastMessageTime': doc['lastMessageTime'] ?? Timestamp(0, 0),
      };
    }).toList();
  }

  Future<void> fixDuplicateChats() async {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) return;

    // Get all chat rooms involving the current user
    final snapshot = await _firestore
        .collection('chatRooms')
        .where('participantEmails', arrayContains: userEmail)
        .get();

    final Map<String, DocumentSnapshot> validChats = {};

    for (var doc in snapshot.docs) {
      final participants = List<String>.from(doc['participantEmails'] ?? []);

      // Skip if not a standard 1:1 chat
      if (participants.length != 2) {
        await doc.reference.delete(); // Delete malformed chats
        continue;
      }

      // Generate correct chat room ID
      participants.sort();
      final correctId = participants.join('_');

      if (doc.id == correctId) {
        // This is a correctly formatted chat - keep it
        validChats[correctId] = doc;
      } else {
        // This is a duplicate/malformed chat
        final correctChat =
            await _firestore.collection('chatRooms').doc(correctId).get();

        if (correctChat.exists) {
          // Merge messages into the correct chat
          final messages = await doc.reference.collection('messages').get();
          final batch = _firestore.batch();

          for (var msg in messages.docs) {
            final newRef = correctChat.reference.collection('messages').doc();
            batch.set(newRef, msg.data());
          }
          await batch.commit();

          // Delete the duplicate
          await doc.reference.delete();
        } else {
          // Rename the chat to the correct ID
          await _firestore.runTransaction((transaction) async {
            // Copy data to new document
            transaction.set(
              _firestore.collection('chatRooms').doc(correctId),
              doc.data()!,
            );

            // Move messages
            final messages = await doc.reference.collection('messages').get();
            for (var msg in messages.docs) {
              transaction.set(
                _firestore
                    .collection('chatRooms')
                    .doc(correctId)
                    .collection('messages')
                    .doc(msg.id),
                msg.data(),
              );
            }

            // Delete old document
            transaction.delete(doc.reference);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? loggedInUserEmail = _auth.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 18.0),
          child: Text(
            'Consultation',
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
      ),
      body: _isMigrating
    ? Center(child: CircularProgressIndicator())
    : loggedInUserEmail == null
        ? Center(child: Text("No user logged in"))
        : StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('chatRooms')
                .where('participantEmails', arrayContains: loggedInUserEmail)
                .orderBy('lastMessageTime', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                        color: Colors.lightBlue));
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("No chats available"));
              }

              final chatPartners = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final vetEmail = (data['participantEmails'] as List)
                    .firstWhere((email) => email != loggedInUserEmail);

                return {
                  'vetEmail': vetEmail,
                  'chatRoomId': doc.id,
                  'lastMessage': data['lastMessage'] ?? 'No messages yet',
                  'lastMessageTime': data['lastMessageTime'] ?? Timestamp(0, 0),
                };
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: chatPartners.length,
                itemBuilder: (context, index) {
                  final partner = chatPartners[index];
                  final vetEmail = partner['vetEmail'] ?? '';
                  final displayName = vetEmail.split('@').first;
                  final chatRoomId = partner['chatRoomId'] ?? '';
                  final lastMessage = partner['lastMessage'] ?? "No messages yet";
                  final lastMessageTime = partner['lastMessageTime'] as Timestamp?;

                  return chatTile(
                    name: displayName,
                    message: lastMessage,
                    time: formatTimestamp(lastMessageTime),
                    imageUrl: "user_guide1.png",
                    isVerified: true,
                    showUnreadBadge: false,
                    chatRoomId: chatRoomId,
                  );
                },
              );
            },
          ),
      floatingActionButton: SizedBox(
        height: 36,
        child: TextButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SelectVeterinarianScreen()),
            );

            if (result != null) {
              final currentUser = _auth.currentUser;
              if (currentUser == null || currentUser.email == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Please sign in to start chatting')));
                return;
              }

              String vetEmail = result['vetEmail'];
              String vetName = result['vetName'];
              String currentUserEmail = currentUser.email!;

              // Generate proper chat room ID
              String chatRoomId = _getChatRoomId(currentUserEmail, vetEmail);

              try {
                await _firestore.collection('chatRooms').doc(chatRoomId).set(
                    {
                      'participants': [
                        currentUserEmail,
                        vetEmail
                      ], // Store as a list
                      'participantEmails': [
                        currentUserEmail,
                        vetEmail
                      ], // Correct array
                      'createdAt': FieldValue.serverTimestamp(),
                      'lastMessage': null, // No initial message
                      'lastMessageTime': null,
                      'lastMessageSender': null,
                      'vetEmail': vetEmail,
                      'userEmail': currentUserEmail,
                    },
                    SetOptions(
                        merge: true)); // Prevent overwriting existing chat
              } catch (e) {
                print('Error creating chat room: $e');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to start chat: ${e.toString()}')));
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatRoomId: chatRoomId,
                    vetName: vetName,
                  ),
                ),
              );
            }
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.lightBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: const Text(
            "New chat",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime messageDate = timestamp.toDate();
    DateTime now = DateTime.now();

    if (messageDate.year == now.year &&
        messageDate.month == now.month &&
        messageDate.day == now.day) {
      return DateFormat('h:mm a').format(messageDate);
    } else if (messageDate.year == now.year) {
      return DateFormat('MMM d').format(messageDate);
    }
    return DateFormat('MM/dd/yyyy').format(messageDate);
  }

  Widget chatTile({
    required String name,
    required String message,
    required String time,
    required String imageUrl,
    bool isVerified = false,
    bool showUnreadBadge = false,
    required String chatRoomId,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage(imageUrl),
        radius: 24,
      ),
      title: Row(
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (isVerified)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.verified, color: Colors.blue, size: 16),
            ),
        ],
      ),
      subtitle: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          if (showUnreadBadge)
            Container(
              margin: EdgeInsets.only(top: 4),
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoomId: chatRoomId,
              vetName: name,
            ),
          ),
        );
      },
    );
  }
}
