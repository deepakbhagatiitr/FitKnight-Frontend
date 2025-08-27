class ChatMessage {
  final int id;
  final String senderName;
  final String? senderImage;
  final String content;
  final String createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderName,
    this.senderImage,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['sender_image'];
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http')) {
      imageUrl = 'https://fitness-backend-km9x.onrender.com$imageUrl';
    }

    return ChatMessage(
      id: json['id'],
      senderName: json['sender_name'] ?? '',
      senderImage: imageUrl,
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> get sender => {
        'username': senderName,
        'profile_image': senderImage,
      };
}
