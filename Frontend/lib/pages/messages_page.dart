import 'package:flutter/material.dart';
import 'package:vetconnect/pages/textarea.dart';

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
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
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
          onPressed: () {},
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
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      },
    );
  }
}
