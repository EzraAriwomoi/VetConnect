import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await ApiService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Text('No notifications yet'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationTile(_notifications[index]);
                  },
                ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'message':
        iconData = Icons.message;
        iconColor = Colors.blue;
        break;
      case 'appointment':
        iconData = Icons.calendar_today;
        iconColor = Colors.green;
        break;
      case 'review':
        iconData = Icons.star;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.2),
        child: Icon(iconData, color: iconColor),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body),
          Text(
            DateFormat('MMM d, h:mm a').format(notification.timestamp),
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      tileColor: notification.isRead ? null : Colors.blue.withOpacity(0.05),
      onTap: () async {
        // Mark as read
        await ApiService.markNotificationAsRead(notification.id);
        
        // Refresh notifications
        _loadNotifications();

        // Navigate based on notification type
        if (notification.type == 'message' && notification.relatedId != null) {
          // Navigate to chat screen
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: {
              'chatId': notification.relatedId,
            },
          );
        } else if (notification.type == 'appointment' && notification.relatedId != null) {
          // Navigate to appointment details
          Navigator.pushNamed(
            context,
            '/appointment_details',
            arguments: {
              'appointmentId': notification.relatedId,
            },
          );
        } else if (notification.type == 'review' && notification.relatedId != null) {
          // Navigate to vet profile
          Navigator.pushNamed(
            context,
            '/vet_profile',
            arguments: {
              'vetId': notification.relatedId,
            },
          );
        }
      },
    );
  }
}
