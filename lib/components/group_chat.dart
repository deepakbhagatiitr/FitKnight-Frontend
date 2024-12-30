import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class GroupChat extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isOrganizer;

  const GroupChat({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isOrganizer,
  });

  @override
  State<GroupChat> createState() => _GroupChatState();
}

class _GroupChatState extends State<GroupChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _currentUsername;
  Timer? _messageTimer;
  int? _roomId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _getCurrentUsername();
    await _joinGroupChat();
    _startMessagePolling();
  }

  Future<void> _getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUsername = prefs.getString('username');
    });
  }

  Future<void> _joinGroupChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('\n=== Joining Group Chat ===');
      print('Group Name: ${widget.groupName}');
      print('Token: $token');

      final response = await http.post(
        Uri.parse(
            'http://192.168.31.36:8000/api/chat/group/${widget.groupName}/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _roomId = data['room_id'];
        print('Room ID: $_roomId');
        await _loadMessages();
      } else {
        throw Exception('Failed to join group chat: ${response.statusCode}');
      }
    } catch (e) {
      print('Error joining group chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join group chat: $e')),
        );
      }
    }
  }

  void _startMessagePolling() {
    _messageTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadMessages(),
    );
  }

  Future<void> _loadMessages() async {
    if (_roomId == null) {
      print('Cannot load messages: Room ID is null');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('\n=== Loading Messages ===');
      print('Room ID: $_roomId');
      print('Token: $token');

      final response = await http.get(
        Uri.parse(
            'http://192.168.31.36:8000/api/chat/rooms/$_roomId/messages/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Received ${data.length} messages');

        setState(() {
          _messages = data.map((message) {
            String imageUrl = message['sender_image'] ?? '';
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = 'http://192.168.31.36:8000$imageUrl';
            }
            return {
              'id': message['id'],
              'text': message['content'],
              'sender': message['sender_name'],
              'profile_image': imageUrl,
              'timestamp': message['created_at'],
              'is_read': message['is_read'],
            };
          }).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) {
      print('Cannot send empty message');
      return;
    }

    if (_roomId == null) {
      print('Cannot send message: Room ID is null');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final messageText = _messageController.text;

      print('\n=== Sending Message ===');
      print('Room ID: $_roomId');
      print('Token: $token');
      print('Message: $messageText');

      final response = await http.post(
        Uri.parse(
            'http://192.168.31.36:8000/api/chat/rooms/$_roomId/messages/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'room': _roomId,
          'content': messageText,
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        print('Message sent successfully');
        _messageController.clear();
        await _loadMessages();
      } else {
        throw Exception(
            'Failed to send message: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isCurrentUser = message['sender'] == _currentUsername;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: isCurrentUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isCurrentUser) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundImage:
                                  message['profile_image']?.isNotEmpty ?? false
                                      ? NetworkImage(message['profile_image'])
                                      : null,
                              child: message['profile_image']?.isEmpty ?? true
                                  ? const Icon(Icons.person, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: isCurrentUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isCurrentUser)
                                    Text(
                                      message['sender'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isCurrentUser
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 12,
                                      ),
                                    ),
                                  Text(
                                    message['text'],
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimestamp(message['timestamp']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isCurrentUser
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isCurrentUser) const SizedBox(width: 24),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }
}
