import 'dart:async';
import 'package:flutter/material.dart';
import 'models/chat_message.dart';
import 'services/chat_service.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input.dart';
import 'widgets/empty_state.dart';

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
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Services
  final ChatService _chatService = ChatService();

  // State variables
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _currentUsername;
  Timer? _messageTimer;
  int? _roomId;
  String? _error;
  String? _chatRoomName;

  static const Duration _messageUpdateInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Chat Initialization
  Future<void> _initializeChat() async {
    try {
      _currentUsername = await _chatService.getCurrentUsername();
      final chatInfo = await _chatService.initializeGroupChat(widget.groupId);

      setState(() {
        _roomId = chatInfo['room_id'];
        _chatRoomName = chatInfo['group_name'];
        _isLoading = false;
        _error = null;
      });

      await _loadMessages();
      _setupMessageUpdates();
    } catch (e) {
      _handleError('Error initializing chat', e);
    }
  }

  // Message Handling
  void _setupMessageUpdates() {
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(_messageUpdateInterval, (timer) {
      if (mounted && _roomId != null) {
        _loadMessages();
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      if (!mounted || _roomId == null) return;

      final messages = await _chatService.loadMessages(_roomId!);
      if (mounted) {
        setState(() {
          _messages = messages;
          _error = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      _handleError('Error loading messages', e);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _roomId == null) return;

    try {
      await _chatService.sendMessage(_roomId!, message);
      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  // Helper Methods
  void _handleError(String context, dynamic error) {
    print('$context: $error');
    if (mounted) {
      setState(() {
        _isLoading = false;
        _error = error.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _scrollToBottom() {
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeChat,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFECE5DD),
      child: Column(
        children: [
          if (_chatRoomName != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.white,
              child: Text(
                _chatRoomName!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? const EmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isCurrentUser =
                          message.sender['username'] == _currentUsername;
                      final showSenderInfo = index == 0 ||
                          _messages[index - 1].sender['username'] !=
                              message.sender['username'];

                      return MessageBubble(
                        message: message,
                        isCurrentUser: isCurrentUser,
                        showSenderInfo: showSenderInfo,
                      );
                    },
                  ),
          ),
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
