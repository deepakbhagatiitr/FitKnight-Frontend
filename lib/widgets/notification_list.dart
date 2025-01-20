import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationList extends StatelessWidget {
  const NotificationList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: notificationProvider.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationProvider.notifications[index];
                    return NotificationTile(
                      notification: notification,
                      onTap: () => _handleNotificationTap(context, notification),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> notification) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    provider.markAsRead(notification['id']);

    switch (notification['notification_type']) {
      case 'join_request':
        Navigator.pushNamed(
          context,
          '/groups/${notification['related_object_id']}/requests',
        );
        break;
      case 'group_chat':
        Navigator.pushNamed(
          context,
          '/chat/${notification['related_object_id']}',
        );
        break;
      case 'buddy_match':
        Navigator.pushNamed(
          context,
          '/buddy/${notification['related_object_id']}',
        );
        break;
    }
  }
}

class NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const NotificationTile({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(notification['title']),
      subtitle: Text(notification['message']),
      trailing: !notification['read']
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
} 