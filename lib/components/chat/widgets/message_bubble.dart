import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../utils/time_formatter.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool showSenderInfo;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    required this.showSenderInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final senderUsername = message.sender['username'];

    return Padding(
      padding: EdgeInsets.only(
        bottom: 8,
        left: isCurrentUser ? 50 : 0,
        right: isCurrentUser ? 0 : 50,
      ),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSenderInfo) _buildSenderInfo(senderUsername),
          _buildMessageContent(),
        ],
      ),
    );
  }

  Widget _buildSenderInfo(String senderUsername) {
    return Padding(
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
    );
  }

  Widget _buildMessageContent() {
    return Container(
      margin: EdgeInsets.only(
        left: !isCurrentUser && !showSenderInfo ? 40 : 0,
      ),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser && showSenderInfo) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(child: _buildMessageBubbleContent()),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final profileImage = message.sender['profile_image'];
    return CircleAvatar(
      radius: 16,
      backgroundImage:
          profileImage?.isNotEmpty == true ? NetworkImage(profileImage) : null,
      backgroundColor: Colors.grey[200],
      child: profileImage?.isEmpty ?? true
          ? const Icon(Icons.person, size: 16, color: Colors.grey)
          : null,
    );
  }

  Widget _buildMessageBubbleContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFDCF8C6) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
          bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.sender['username'],
            style: TextStyle(
              fontSize: 13,
              color: Colors.teal[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message.content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            TimeFormatter.formatTimestamp(message.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
