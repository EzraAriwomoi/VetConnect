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

  Map<K, List<T>> groupBy<T, K>(Iterable<T> items, K Function(T) keyFunction) {
    final map = <K, List<T>>{};
    for (final item in items) {
      final key = keyFunction(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
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
      body: loggedInUserEmail == null
          ? Center(child: Text("No user logged in"))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chatRooms')
                  .doc(loggedInUserEmail)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Colors.lightBlue,));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No chats available"));
                }

                // Group messages by chat room (vet email)
                final messagesByChat = groupBy(
                  snapshot.data!.docs,
                  (doc) => doc.reference.parent.parent?.parent.id ?? '',
                );

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: messagesByChat.entries.map((entry) {
                    final vetEmail = entry.key;
                    final lastMessage = entry.value.first;

                    return chatTile(
                      name: vetEmail,
                      message: lastMessage['text'] ?? "No messages yet",
                      time: formatTimestamp(lastMessage['timestamp']),
                      imageUrl: "assets/user_guide1.png",
                      isVerified: true,
                      showUnreadBadge: false,
                      chatRoomId: vetEmail,
                    );
                  }).toList(),
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
              String chatRoomId = result['chatRoomId'];
              String vetName = result['vetName'];

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatScreen(chatRoomId: chatRoomId, vetName: vetName),
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

  // Add this timestamp formatter (similar to your ChatScreen)
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime messageDate = timestamp.toDate();
    DateTime now = DateTime.now();

    if (messageDate.year == now.year &&
        messageDate.month == now.month &&
        messageDate.day == now.day) {
      return "Today";
    }
    return DateFormat("MMM d").format(messageDate);
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
      subtitle: Text(message),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChatScreen(
                    chatRoomId: chatRoomId,
                    vetName: name,
                  )),
        );
      },
    );
  }
}
