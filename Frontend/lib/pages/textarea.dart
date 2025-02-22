import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  FocusNode _messageFocusNode = FocusNode();
  TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;
  bool _showEmojiPicker = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        setState(() => _showEmojiPicker = false);
      }
    });
  }

  @override
  void dispose() {
    _messageFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/user_guide1.png'),
              radius: 18,
            ),
            const SizedBox(width: 10),
            const Text(
              'Dr. David',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.verified, color: Colors.blue, size: 16),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.call), onPressed: () {}),
          IconButton(icon: Icon(Icons.video_call), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                _buildWelcomeMessage(),
                const SizedBox(height: 10),
                _buildDateLabel("Today"),
                const SizedBox(height: 10),
                _buildSentMessage("11:43", "Thank you for reaching out!"),
                _buildReceivedMessage("11:40", "Sure, I'll check that out."),
                if (_selectedImage != null) _buildImagePreview(_selectedImage!),
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
          style: TextStyle(fontSize: 12,color: Color.fromARGB(255, 114, 114, 114)),
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

  Widget _buildReceivedMessage(String time, String message) {
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
              onPressed: _isTyping ? _sendMessage : null,
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

  void _sendMessage() {
    print("Message Sent: ${_messageController.text}");
    _messageController.clear();
    setState(() => _isTyping = false);
  }

  void _pickImageFromGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Widget _buildImagePreview(File image) {
    return Container(
      margin: EdgeInsets.all(10),
      child: Image.file(image, height: 150),
    );
  }
}
