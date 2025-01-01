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
    Key? key,
    required this.groupId,
    required this.groupName,
    this.isOrganizer = false,
  }) : super(key: key);

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
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      print('\n=== Initializing Group Chat ===');
      print('Group ID: ${widget.groupId}');
      print('Group Name: ${widget.groupName}');

      await _getCurrentUsername();

      // First initialize/join the group chat to get room ID
      final roomId = await _initializeGroupChat();
      if (roomId != null) {
        print('Successfully got room ID: $roomId');
        setState(() {
          _roomId = roomId;
          _isLoading = false;
        });

        // Only after getting room ID, start loading messages
        await _loadMessages();
        _setupMessageUpdates();
      } else {
        throw Exception('Failed to get room ID');
      }
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<int?> _initializeGroupChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('\n=== Getting Chat Room ID ===');
      print('Group Name: ${widget.groupName}');
      print('Token: $token');

      // First get the room ID using group name
      final response = await http.post(
        Uri.parse(
            'http://192.168.31.36:8000/api/chat/group/${widget.groupName}/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      print('Room Init Status Code: ${response.statusCode}');
      print('Room Init Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final roomId = data['room_id'];
        print('Got Room ID: $roomId');
        return roomId;
      } else {
        throw Exception('Failed to get chat room: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting chat room: $e');
      rethrow;
    }
  }

  void _setupMessageUpdates() {
    // Cancel any existing timer
    _messageTimer?.cancel();

    // Set up periodic message updates
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _roomId != null) {
        _loadMessages();
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      if (!mounted || _roomId == null) {
        print(
            'Cannot load messages: ${!mounted ? "Widget not mounted" : "No room ID"}');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('\n=== Loading Messages ===');
      print('Room ID: $_roomId');

      final response = await http.get(
        Uri.parse(
            'http://192.168.31.36:8000/api/chat/rooms/$_roomId/messages/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      print('Messages Status Code: ${response.statusCode}');
      print('Raw Response: ${response.body}');

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Received ${data.length} messages');

        setState(() {
          _messages = data
              .map<Map<String, dynamic>>((dynamic message) {
                try {
                  if (message is! Map<String, dynamic>) {
                    print('Invalid message format: $message');
                    return {};
                  }

                  // Process profile image URL
                  String imageUrl = message['sender_image']?.toString() ?? '';
                  if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                    imageUrl = 'http://192.168.31.36:8000$imageUrl';
                  }

                  print(
                      'Processing message - Username: ${message['sender_name']}, Content: ${message['content']}');

                  return {
                    'id': message['id']?.toString() ?? '',
                    'content': message['content']?.toString() ?? '',
                    'sender': {
                      'username':
                          message['sender_name']?.toString() ?? 'Unknown',
                      'profile_image': imageUrl,
                      'id': message['sender']?.toString() ?? '',
                    },
                    'created_at': message['created_at']?.toString() ??
                        DateTime.now().toIso8601String(),
                    'is_read': message['is_read'] == true,
                  };
                } catch (e) {
                  print('Error processing message: $e');
                  return {};
                }
              })
              .where((message) => message.isNotEmpty)
              .toList();

          // Sort messages by timestamp
          _messages.sort((a, b) => DateTime.parse(a['created_at'])
              .compareTo(DateTime.parse(b['created_at'])));
        });

        // Debug print processed messages
        print('\n=== Processed Messages ===');
        for (var msg in _messages) {
          print('Message from ${msg['sender']['username']}: ${msg['content']}');
        }

        // Scroll to bottom after loading messages
        if (_scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        }
      }
    } catch (e, stackTrace) {
      print('Error loading messages: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = 'Failed to load messages: $e';
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _roomId == null) {
      print(
          'Cannot send message: ${_messageController.text.isEmpty ? "Empty message" : "No room ID"}');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final messageText = _messageController.text;

      print('\n=== Sending Message ===');
      print('Room ID: $_roomId');
      print('Message: $messageText');

      // Include both room and content in the request body
      final response = await http.post(
        Uri.parse(
            'http://192.168.31.36:8000/api/chat/rooms/$_roomId/messages/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'room': _roomId, // Add the room ID in the request body
          'content': messageText,
        }),
      );

      print('Send Message Status Code: ${response.statusCode}');
      print('Send Message Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Message sent successfully');
        _messageController.clear();
        await _loadMessages();

        // Scroll to bottom after sending message
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
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

  Future<void> _getCurrentUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      print('\n=== Getting Current Username ===');
      print('Username from SharedPreferences: $username');

      if (mounted) {
        setState(() {
          _currentUsername = username;
        });
      }
    } catch (e) {
      print('Error getting username: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to get username';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: _initializeChat,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFECE5DD), // WhatsApp chat background color
      child: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isCurrentUser =
                          message['sender']['username'] == _currentUsername;
                      final senderUsername = message['sender']['username'];
                      final showSenderInfo = index == 0 ||
                          _messages[index - 1]['sender']['username'] !=
                              senderUsername;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: 8,
                          left: isCurrentUser ? 50 : 0,
                          right: isCurrentUser ? 0 : 50,
                        ),
                        child: Column(
                          crossAxisAlignment: isCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (showSenderInfo)
                              Padding(
                                padding: EdgeInsets.only(
                                  left: isCurrentUser ? 0 : 12,
                                  right: isCurrentUser ? 12 : 0,
                                  bottom: 4,
                                ),
                                child: Text(
                                  senderUsername,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.teal[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            Container(
                              margin: EdgeInsets.only(
                                left:
                                    !isCurrentUser && !showSenderInfo ? 40 : 0,
                              ),
                              child: Row(
                                mainAxisAlignment: isCurrentUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isCurrentUser && showSenderInfo) ...[
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: message['sender']
                                                      ['profile_image']
                                                  ?.isNotEmpty ??
                                              false
                                          ? NetworkImage(message['sender']
                                              ['profile_image'])
                                          : null,
                                      backgroundColor: Colors.grey[200],
                                      child: message['sender']['profile_image']
                                                  ?.isEmpty ??
                                              true
                                          ? const Icon(Icons.person,
                                              size: 16, color: Colors.grey)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCurrentUser
                                            ? const Color(
                                                0xFFDCF8C6) // WhatsApp green bubble
                                            : Colors
                                                .white, // White bubble for others
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: Radius.circular(
                                              isCurrentUser ? 16 : 4),
                                          bottomRight: Radius.circular(
                                              isCurrentUser ? 4 : 16),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            senderUsername,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.teal[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            message['content'],
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _formatTimestamp(
                                                    message['created_at']),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              if (isCurrentUser) ...[
                                                const SizedBox(width: 3),
                                                Icon(
                                                  message['is_read']
                                                      ? Icons.done_all
                                                      : Icons.done,
                                                  size: 14,
                                                  color: message['is_read']
                                                      ? const Color(
                                                          0xFF34B7F1) // WhatsApp blue ticks
                                                      : Colors.grey[600],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Message',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                              ),
                              style: const TextStyle(fontSize: 16),
                              maxLines: 4,
                              minLines: 1,
                              textInputAction: TextInputAction.newline,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A884), // WhatsApp green
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                      padding: const EdgeInsets.only(left: 3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
