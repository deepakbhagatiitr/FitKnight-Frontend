class GroupDetails {
  final String id;
  final String name;
  final String activityType;
  final String location;
  final String schedule;
  final String description;
  final String createdAt;
  final String organizerName;
  final bool isOrganizer;

  GroupDetails({
    required this.id,
    required this.name,
    required this.activityType,
    required this.location,
    required this.schedule,
    required this.description,
    required this.createdAt,
    required this.organizerName,
    required this.isOrganizer,
  });

  factory GroupDetails.fromJson(
      Map<String, dynamic> json, String currentUsername) {
    return GroupDetails(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      activityType: json['activity_type'] ?? '',
      location: json['location'] ?? '',
      schedule: json['schedule'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
      organizerName: json['organizer_name'] ?? '',
      isOrganizer: (json['organizer_name'] ?? '') == currentUsername,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'activity_type': activityType,
      'location': location,
      'schedule': schedule,
      'description': description,
      'created_at': createdAt,
      'organizer_name': organizerName,
      'is_organizer': isOrganizer,
    };
  }
}

class GroupMember {
  final String id;
  final String username;
  final String profileImage;
  final String role;

  GroupMember({
    required this.id,
    required this.username,
    required this.profileImage,
    required this.role,
  });

  factory GroupMember.fromJson(
      Map<String, dynamic> json, String organizerUsername) {
    String imageUrl = json['profile_image'] ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = 'http://10.81.1.137:8000$imageUrl';
    }

    return GroupMember(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      profileImage: imageUrl,
      role: json['username'] == organizerUsername ? 'Organizer' : 'Member',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'profile_image': profileImage,
      'role': role,
    };
  }
}

class JoinRequest {
  final String id;
  final String userId;
  final String username;
  final String profileImage;
  final String status;
  final String createdAt;

  JoinRequest({
    required this.id,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.status,
    required this.createdAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    String imageUrl = json['user']['profile_image'] ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = 'http://10.81.1.137:8000$imageUrl';
    }

    return JoinRequest(
      id: json['id'].toString(),
      userId: json['user']['id'].toString(),
      username: json['user']['username'] ?? '',
      profileImage: imageUrl,
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'profile_image': profileImage,
      'status': status,
      'created_at': createdAt,
    };
  }
}
