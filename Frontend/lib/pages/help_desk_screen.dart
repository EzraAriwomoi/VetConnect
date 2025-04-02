import 'package:flutter/material.dart';
import '../models/help_desk_post.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class HelpDeskScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  const HelpDeskScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  _HelpDeskScreenState createState() => _HelpDeskScreenState();
}

class _HelpDeskScreenState extends State<HelpDeskScreen> {
  List<HelpDeskPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final posts = await ApiService.getHelpDeskPosts();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading help desk posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help Desk'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPosts,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(child: Text('No posts yet'))
              : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    return _buildPostCard(_posts[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showAddPostDialog(),
      ),
    );
  }

  Widget _buildPostCard(HelpDeskPost post) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(post.userName.substring(0, 1).toUpperCase()),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(post.timestamp),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post.animalType,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              post.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(post.content),
            if (post.imageUrl != null) ...[
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${post.comments.length} comments'),
                TextButton.icon(
                  icon: Icon(Icons.comment),
                  label: Text('Comment'),
                  onPressed: () => _showCommentsDialog(post),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedAnimalType = 'Dog';
    final animalTypes = ['Dog', 'Cat', 'Bird', 'Reptile', 'Other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add New Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedAnimalType,
                  decoration: InputDecoration(
                    labelText: 'Animal Type',
                    border: OutlineInputBorder(),
                  ),
                  items: animalTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedAnimalType = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                  final success = await ApiService.addHelpDeskPost(
                    title: titleController.text,
                    content: contentController.text,
                    animalType: selectedAnimalType,
                  );
                  
                  if (success) {
                    Navigator.pop(context);
                    _loadPosts();
                  }
                }
              },
              child: Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsDialog(HelpDeskPost post) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comments'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Expanded(
                child: post.comments.isEmpty
                    ? Center(child: Text('No comments yet'))
                    : ListView.builder(
                        itemCount: post.comments.length,
                        itemBuilder: (context, index) {
                          final comment = post.comments[index];
                          return ListTile(
                            title: Row(
                              children: [
                                Text(
                                  comment.userName,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  DateFormat('MMM d').format(comment.timestamp),
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            subtitle: Text(comment.comment),
                          );
                        },
                      ),
              ),
              Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () async {
                      if (commentController.text.isNotEmpty) {
                        final success = await ApiService.addCommentToHelpDesk(
                          postId: post.id,
                          comment: commentController.text,
                        );
                        
                        if (success) {
                          commentController.clear();
                          Navigator.pop(context);
                          _loadPosts();
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
