import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatService {
  static const String _baseUrl =
      'https://fitness-backend-km9x.onrender.com/api';
  int? _currentRoomId;

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<Map<String, dynamic>> initializeGroupChat(String groupId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/group/$groupId/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print(
          'Initialize chat response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final data = responseData['data'];
          _currentRoomId = data['room_id'];
          return {
            'room_id': data['room_id'],
            'group_id': data['group_id'],
            'group_name': data['group_name'],
            'message': data['message'],
          };
        }
        throw Exception('Invalid response format');
      }

      if (response.statusCode == 403) {
        final error = jsonDecode(response.body);
        throw Exception(
            error['error'] ?? 'Must be member of group to access chat');
      }
      if (response.statusCode == 404) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Group not found');
      }

      throw Exception('Failed to initialize chat: ${response.statusCode}');
    } catch (e) {
      print('Error initializing chat: $e');
      rethrow;
    }
  }

  Future<List<ChatMessage>> loadMessages(int roomId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/rooms/$roomId/messages/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          if (_currentRoomId != null)
            'X-Current-Chat-Id': _currentRoomId.toString(),
        },
      );

      print(
          'Load messages response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((message) => ChatMessage.fromJson(message)).toList()
          ..sort((a, b) => DateTime.parse(a.createdAt)
              .compareTo(DateTime.parse(b.createdAt)));
      }

      if (response.statusCode == 403) {
        final error = jsonDecode(response.body);
        throw Exception(
            error['error'] ?? 'Must be a participant to view messages');
      }
      if (response.statusCode == 404) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Chat room not found');
      }

      throw Exception('Failed to load messages: ${response.statusCode}');
    } catch (e) {
      print('Error loading messages: $e');
      rethrow;
    }
  }

  Future<void> sendMessage(int roomId, String content) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/rooms/$roomId/messages/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'X-Current-Chat-Id': roomId.toString(),
        },
        body: jsonEncode({
          'content': content,
          'room_id': roomId,
        }),
      );

      print('Send message response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      }

      if (response.statusCode == 403) {
        final error = jsonDecode(response.body);
        throw Exception(
            error['error'] ?? 'Must be a participant to send messages');
      }
      if (response.statusCode == 404) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Chat room not found');
      }

      throw Exception('Failed to send message: ${response.statusCode}');
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
}
