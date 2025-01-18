import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatService {
  static const String _baseUrl = 'http://10.81.1.209:8000/api';

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<int?> initializeGroupChat(String groupName) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/group/$groupName/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['room_id'];
      }
      throw Exception('Failed to get chat room: ${response.statusCode}');
    } catch (e) {
      print('Error getting chat room: $e');
      rethrow;
    }
  }

  Future<List<ChatMessage>> loadMessages(int roomId) async {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/chat/rooms/$roomId/messages/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((message) => ChatMessage.fromJson(message)).toList()
        ..sort((a, b) =>
            DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)));
    }
    throw Exception('Failed to load messages: ${response.statusCode}');
  }

  Future<void> sendMessage(int roomId, String content) async {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/rooms/$roomId/messages/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'room': roomId,
        'content': content,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }
}
