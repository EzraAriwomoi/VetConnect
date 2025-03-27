import 'package:flutter/material.dart';
import 'package:vetconnect/pages/chat_screen.dart';
import 'package:vetconnect/pages/select_vet_page.dart';

class MessagesPage extends StatefulWidget {
  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  @override
  Widget build(BuildContext context) {
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
        actions: [
  PopupMenuButton<String>(
    onSelected: (value) {
      if (value == 'clear_chat') {
        // Handle clearing chat
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Clear Chat'),
            content: Text('Are you sure you want to clear this chat?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Add logic to clear chat
                  Navigator.of(context).pop();
                },
                child: Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      } else if (value == 'mute') {
        // Handle muting chat notifications
      } else if (value == 'block') {
        // Handle blocking user
      } else if (value == 'report') {
        // Handle reporting user
      }
    },
    itemBuilder: (BuildContext context) => [
      PopupMenuItem<String>(
        value: 'clear_chat',
        child: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 10),
            Text('Clear Chat', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'mute',
        child: Row(
          children: [
            Icon(Icons.notifications_off, color: Colors.black),
            SizedBox(width: 10),
            Text('Mute Notifications'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'block',
        child: Row(
          children: [
            Icon(Icons.block, color: Colors.black),
            SizedBox(width: 10),
            Text('Block User'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'report',
        child: Row(
          children: [
            Icon(Icons.report, color: Colors.black),
            SizedBox(width: 10),
            Text('Report Issue'),
          ],
        ),
      ),
    ],
    icon: Icon(Icons.more_vert, color: Colors.black),
    tooltip: 'Menu',
    offset: Offset(0, 40),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    color: Colors.white,
  ),
],

      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          chatTile(
            name: "Dr. David",
            message: "✔️ Thank you sir, will sure do 👍🏼👍🏼",
            time: "Today",
            imageUrl: "assets/user_guide1.png",
            isVerified: true,
            showUnreadBadge: false,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(
                color: Color.fromARGB(255, 226, 226, 226), thickness: 1),
          ),
          chatTile(
            name: "Dr. Joshua",
            message: "Try the other medication...",
            time: "30/01/25",
            imageUrl: "assets/user_guide2.jpg",
            isVerified: false,
            showUnreadBadge: true,
          ),
        ],
      ),
      floatingActionButton: SizedBox(
  height: 36,
  child: TextButton(
    onPressed: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SelectVeterinarianScreen()),
      );

      if (result != null) {
        String chatRoomId = result['chatRoomId'];
        String vetName = result['vetName'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoomId: chatRoomId, vetName: vetName),
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

  Widget chatTile({
    required String name,
    required String message,
    required String time,
    required String imageUrl,
    bool isVerified = false,
    bool showUnreadBadge = false,
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                time,
                style: const TextStyle(
                    color: Color.fromARGB(255, 184, 183, 183), fontSize: 12),
              ),
              if (showUnreadBadge)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 128, 208, 245),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    "1",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            color: Color.fromARGB(255, 184, 183, 183),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(vetName: '', chatRoomId: '',)),
        );
      },
    );
  }
}
