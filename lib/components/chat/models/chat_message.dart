class ChatMessage {
  final String id;
  final String content;
  final Map<String, dynamic> sender;
  final String createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    String imageUrl = json['sender_image']?.toString() ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = 'http://10.81.1.209:8000$imageUrl';
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      sender: {
        'username': json['sender_name']?.toString() ?? 'Unknown',
        'profile_image': imageUrl,
        'id': json['sender']?.toString() ?? '',
      },
      createdAt:
          json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      isRead: json['is_read'] == true,
    );
  }
}
