import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
  final String chatRoomId;
  final String vetName;

  const ChatScreen(
      {super.key, required this.vetName, required this.chatRoomId});
}

class _ChatScreenState extends State<ChatScreen> {
  FocusNode _messageFocusNode = FocusNode();
  TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;
  bool _showEmojiPicker = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String vetName = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchVetName();
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        setState(() => _showEmojiPicker = false);
      }
    });
  }

  Future<void> _fetchVetName() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.166.58:5000/get_vet_name?vet_id=${widget.chatRoomId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          vetName = jsonDecode(response.body)['name'];
        });
      } else {
        setState(() {
          vetName = "Vet Not Found";
        });
      }
    } catch (e) {
      setState(() {
        vetName = "Error Fetching Name";
      });
    }
  }

  @override
  void dispose() {
    _messageFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";

    DateTime messageDate = timestamp.toDate();
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(Duration(days: 1));
    DateTime lastWeek = today.subtract(Duration(days: 7));

    if (messageDate.isAfter(today)) {
      return "Today";
    } else if (messageDate.isAfter(yesterday)) {
      return "Yesterday";
    } else if (messageDate.isAfter(lastWeek)) {
      return getWeekdayName(messageDate.weekday);
    } else {
      return DateFormat("E, d MMM").format(messageDate);
    }
  }

  String getWeekdayName(int weekday) {
    const weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ];
    return weekdays[weekday - 1];
  }

  void _sendMessage(String recipientEmail) async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    String senderEmail = currentUser.email!;

    await _firestore
        .collection('chatRooms')
        .doc(senderEmail)
        .collection(recipientEmail)
        .doc('messages')
        .collection('messages')
        .add({
      'senderId': currentUser.uid,
      'senderEmail': senderEmail,
      'text': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    setState(() {
      _isTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/user_guide1.png'),
              radius: 18,
            ),
            const SizedBox(width: 10),
            Text(
              'Dr. ${vetName.split(' ')[0]}',
              style: TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 5),
            const Icon(Icons.verified, color: Colors.black, size: 16),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.call), onPressed: () {}),
          IconButton(icon: Icon(Icons.video_call), onPressed: () {}),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'view_contact') {
              } else if (value == 'search') {
              } else if (value == 'clear_chat') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Clear Chat'),
                    content: Text('Are you sure you want to delete this chat?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text('Clear',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 250, 109, 99),
                            )),
                      ),
                    ],
                  ),
                );
              } else if (value == 'mute') {
              } else if (value == 'report') {}
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'view_contact',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.black),
                    SizedBox(width: 10),
                    Text('View Contact'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Search Messages'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'clear_chat',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete,
                      color: const Color.fromARGB(255, 250, 109, 99),
                    ),
                    SizedBox(width: 10),
                    Text('Clear Chat',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 250, 109, 99),
                        )),
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
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Report/Block User'),
                  ],
                ),
              ),
            ],
            icon: Icon(Icons.more_vert, color: Colors.black),
            offset: Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 15),
                _buildWelcomeMessage(),
                const SizedBox(height: 10),
                Expanded(
                    child: StreamBuilder(
                  stream: _firestore
                      .collection('chatRooms')
                      .doc(_auth.currentUser?.email)
                      .collection(widget.chatRoomId)
                      .doc('messages')
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    var messages = snapshot.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        var message = messages[index];
                        bool isSentByMe =
                            message['senderId'] == _auth.currentUser?.uid;

                        Timestamp? timestamp =
                            message['timestamp'] as Timestamp?;
                        String formattedDate = formatTimestamp(timestamp);

                        bool showDateLabel = index == messages.length - 1 ||
                            (index < messages.length - 1 &&
                                formatTimestamp(messages[index + 1]['timestamp']
                                        as Timestamp?) !=
                                    formattedDate);

                        return Column(
                          children: [
                            if (showDateLabel) _buildDateLabel(formattedDate),
                            isSentByMe
                                ? _buildSentMessage("", message['text'])
                                : _buildReceivedMessage("", message['text'],
                                    message['senderEmail'] ?? "Unknown Sender"),
                          ],
                        );
                      },
                    );
                  },
                )),
              ],
            ),
          ),
          _buildMessageInputField(),
          if (_showEmojiPicker) _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.amber[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          "Thank you for reaching out! Feel free to ask any question. I`m here to help ensure your furry, feathered, or scaly friend get the best care possible. Feel free to share your concerns, and I`ll get back to you as soon as possible. If this is an urgent matter, please contact the clinic directly at 254 712 345678.",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12, color: Color.fromARGB(255, 114, 114, 114)),
        ),
      ),
    );
  }

  Widget _buildDateLabel(String date) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(date, style: TextStyle(color: Colors.blue.shade900)),
      ),
    );
  }

  Widget _buildSentMessage(String time, String message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message, style: TextStyle(fontSize: 16)),
            SizedBox(height: 5),
            Text(time, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedMessage(
      String time, String message, String senderEmail) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(senderEmail,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            SizedBox(height: 5),
            Text(message, style: TextStyle(fontSize: 16)),
            SizedBox(height: 5),
            Text(time, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: const Color.fromARGB(255, 235, 235, 235))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 234, 254, 255),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.lightBlue, width: 1),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined,
                        color: Colors.lightBlue),
                    onPressed: () {
                      if (_messageFocusNode.hasFocus) {
                        FocusScope.of(context).unfocus();
                        Future.delayed(Duration(milliseconds: 100), () {
                          setState(() => _showEmojiPicker = true);
                        });
                      } else {
                        setState(() => _showEmojiPicker = !_showEmojiPicker);
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      focusNode: _messageFocusNode,
                      cursorColor: Colors.lightBlue,
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type here...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onChanged: (text) =>
                          setState(() => _isTyping = text.isNotEmpty),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file, color: Colors.lightBlue),
                    onPressed: _pickImageFromGallery,
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt_outlined,
                        color: Colors.lightBlue),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromARGB(255, 234, 254, 255),
              border: Border.all(color: Colors.lightBlue, width: 1),
            ),
            padding: EdgeInsets.all(2),
            child: IconButton(
              icon: Icon(_isTyping ? Icons.send : Icons.mic,
                  color: Colors.lightBlue),
              onPressed: _isTyping ? () => _sendMessage(widget.chatRoomId) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _messageController.text += emoji.emoji;
          setState(() {});
        },
      ),
    );
  }

  void _pickImageFromGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
    }
  }

  // Widget _buildImagePreview(File image) {
  //   return Container(
  //     margin: EdgeInsets.all(10),
  //     child: Image.file(image, height: 150),
  //   );
  // }
}
