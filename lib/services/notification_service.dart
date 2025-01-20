import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String baseUrl = 'http://10.81.93.48:8000/api';
  static WebSocketChannel? _channel;
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isConnecting = false;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const String CHANNEL_ID = 'high_importance_channel';
  static const String CHANNEL_NAME = 'High Importance Notifications';
  static const String CHANNEL_DESCRIPTION =
      'This channel is used for important notifications.';

  static Future<void> initialize() async {
    try {
      // Initialize Android settings with default app icon
      const androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Initialize iOS settings
      const iosInitSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: false,
      );

      // Initialize settings for both platforms
      const initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: iosInitSettings,
      );

      print('Initializing notification plugin...');

      // Initialize the plugin and request permissions
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      print('Notification plugin initialized successfully');

      // Request permission for Android 13 and above
      final platform = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (platform != null) {
        print('Requesting Android notifications permission...');
        final granted = await platform.requestNotificationsPermission();
        print('Android notifications permission granted: $granted');

        // Create Android notification channel with high importance
        const androidChannel = AndroidNotificationChannel(
          CHANNEL_ID,
          CHANNEL_NAME,
          description: CHANNEL_DESCRIPTION,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
          enableLights: true,
        );

        print('Creating Android notification channel...');
        await platform.createNotificationChannel(androidChannel);
        print('Android notification channel created successfully');
      }

      print('Notification service initialization completed');
    } catch (e, stackTrace) {
      print('Error initializing notification service: $e');
      print('Stack trace: $stackTrace');
    }
  }

  static void _handleNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap based on payload
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        // Handle different notification types
        if (data['type'] == 'join_request') {
          // Navigate to join requests page
          print('Should navigate to join requests page');
        }
      } catch (e) {
        print('Error handling notification tap: $e');
      }
    }
  }

  static Future<void> showNotification(
      Map<String, dynamic> notification) async {
    try {
      print('Preparing to show notification: $notification');

      // Create Android-specific details
      final androidDetails = AndroidNotificationDetails(
        CHANNEL_ID,
        CHANNEL_NAME,
        channelDescription: CHANNEL_DESCRIPTION,
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        fullScreenIntent: true,
        ongoing: false,
        styleInformation: BigTextStyleInformation(
          notification['message'] ?? '',
          htmlFormatBigText: true,
          contentTitle: notification['title'] ?? 'New Notification',
          htmlFormatContentTitle: true,
        ),
      );

      // Create iOS-specific details
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      // Combine platform-specific details
      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Generate unique ID for the notification
      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      print('Attempting to show notification with ID: $notificationId');
      print('Title: ${notification['title']}');
      print('Message: ${notification['message']}');
      print('Type: ${notification['type']}');

      // Show the notification
      await _notifications.show(
        notificationId,
        notification['title'] ?? 'New Notification',
        notification['message'] ?? '',
        platformDetails,
        payload: json.encode(notification),
      );

      print('Notification shown successfully with ID: $notificationId');
    } catch (e, stackTrace) {
      print('Error showing notification: $e');
      print('Stack trace: $stackTrace');
      print('Notification data that caused error: $notification');
    }
  }

  static void connectWebSocket(String token) async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      // Close existing connection if any
      await _channel?.sink.close();
      _channel = null;

      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final username = prefs.getString('username');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final wsUrl = Uri.parse(
          'ws://10.81.93.48:8000/ws/notifications/?token=$token&user_id=$userId');
      print('Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(wsUrl);
      print('WebSocket connected successfully');

      _channel!.stream.listen(
        (message) async {
          try {
            _reconnectAttempts = 0; // Reset attempts on successful message
            print('WebSocket message received: $message');

            final data = json.decode(message);
            print('Decoded WebSocket data: $data');

            // Handle join request notifications
            if (data['type'] == 'join_request') {
              print('Processing join request notification');
              // Check if the current user is the group organizer
              if (data['group_organizer'] == username) {
                await showNotification({
                  'title': 'New Join Request',
                  'message':
                      '${data['requester_name']} wants to join your group ${data['group_name']}',
                  'type': 'join_request',
                  'data': data,
                  'priority': 'high',
                  'importance': 'max',
                });
              }
            }
            // Handle chat message notifications
            else if (data['type'] == 'group_chat') {
              print('Processing chat message notification');
              await showNotification({
                'title': 'New Message',
                'message': data['message'],
                'type': 'chat_message',
                'data': data,
                'priority': 'high',
                'importance': 'max',
              });
            }
            // Handle notifications (including chat messages)
            else if (data['type'] == 'notification') {
              print('Processing notification: ${data['data']}');
              final notificationData = data['data'];

              // Handle chat messages specifically
              if (notificationData['notification_type'] == 'group_chat') {
                print('Processing group chat notification');
                await showNotification({
                  'title': notificationData['title'] ?? 'New Message',
                  'message': notificationData['message'] ?? '',
                  'type': 'chat_message',
                  'data': {
                    'room_id': notificationData['related_object_id'],
                    'is_read': notificationData['is_read'] ?? false,
                    ...notificationData,
                  },
                  'priority': 'high',
                  'importance': 'max',
                });
              } else {
                // Handle other types of notifications
                await showNotification({
                  'title': notificationData['title'] ?? 'New Notification',
                  'message': notificationData['message'] ?? '',
                  'type': notificationData['notification_type'] ?? 'general',
                  'data': notificationData,
                  'priority': 'high',
                  'importance': 'max',
                });
              }
            }
            // Handle request response notifications
            else if (data['type'] == 'request_response') {
              print('Processing request response notification');
              final status = data['status']?.toLowerCase();
              final message = status == 'approved'
                  ? 'Your join request was approved!'
                  : 'Your join request was rejected.';
              await showNotification({
                'title': 'Join Request Update',
                'message': message,
                'type': 'request_response',
                'data': data,
                'priority': 'high',
                'importance': 'max',
              });
            }
          } catch (e, stackTrace) {
            print('Error processing WebSocket message: $e');
            print('Stack trace: $stackTrace');
            print('Raw message that caused error: $message');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleReconnect(token);
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleReconnect(token);
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('WebSocket connection error: $e');
      _handleReconnect(token);
    } finally {
      _isConnecting = false;
    }
  }

  static void _handleReconnect(String token) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    print(
        'Attempting to reconnect (${_reconnectAttempts}/$_maxReconnectAttempts)');

    Future.delayed(
      Duration(seconds: _calculateBackoffDuration(_reconnectAttempts)),
      () => connectWebSocket(token),
    );
  }

  static int _calculateBackoffDuration(int attempt) {
    // Exponential backoff: 2^n seconds (max 30 seconds)
    return (1 << attempt).clamp(1, 30);
  }

  static Future<List<dynamic>> fetchNotifications(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to fetch notifications');
  }

  static Future<void> markAsRead(String token, int notificationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/$notificationId/read/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  static Future<void> clearAllNotifications(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/clear/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to clear notifications');
      }
    } catch (e) {
      print('Error clearing notifications: $e');
      throw Exception('Failed to clear notifications: $e');
    }
  }
}
