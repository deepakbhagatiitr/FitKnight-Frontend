import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  String? _token;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void initialize(String token) {
    _token = token;
    NotificationService.connectWebSocket(token);
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    if (_token == null) return;

    try {
      _notifications = await NotificationService.fetchNotifications(_token!);
      _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Future<void> markAsRead(int notificationId) async {
    if (_token == null) return;

    try {
      await NotificationService.markAsRead(_token!, notificationId);
      await fetchNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n['read']).length;
  }
}
