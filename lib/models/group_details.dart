class Goal {
  final String id;
  final String title;
  final String description;
  final String type; // 'daily' or 'weekly'
  final bool isCompleted;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.isCompleted,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'is_completed': isCompleted,
    };
  }
}

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
  final List<Goal> goals;
  final String organizerPhone;
  final String organizerEmail;
  final String organizerLocation;

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
    required this.goals,
    required this.organizerPhone,
    required this.organizerEmail,
    required this.organizerLocation,
  });

  factory GroupDetails.fromJson(
      Map<String, dynamic> json, String currentUsername) {
    List<Goal> goals = [];

    // Parse goals from API if available, otherwise use dummy data
    if (json['goals'] != null) {
      goals =
          (json['goals'] as List).map((goal) => Goal.fromJson(goal)).toList();
    } else {
      // Create dummy goals data
      goals = [
        // Daily Goals
        Goal(
          id: '1',
          title: 'Morning Workout',
          description: '30 minutes cardio session',
          type: 'daily',
          isCompleted: false,
        ),
        Goal(
          id: '2',
          title: 'Evening Workout',
          description: '45 minutes strength training',
          type: 'daily',
          isCompleted: true,
        ),
        Goal(
          id: '3',
          title: 'Stretching',
          description: '15 minutes flexibility exercises',
          type: 'daily',
          isCompleted: false,
        ),
        // Weekly Goals
        Goal(
          id: '4',
          title: 'Distance Target',
          description: 'Run 20km total',
          type: 'weekly',
          isCompleted: false,
        ),
        Goal(
          id: '5',
          title: 'Group Sessions',
          description: 'Attend 3 group workouts',
          type: 'weekly',
          isCompleted: false,
        ),
        Goal(
          id: '6',
          title: 'Weight Training',
          description: 'Complete 4 strength sessions',
          type: 'weekly',
          isCompleted: false,
        ),
      ];
    }

    // Get organizer profile information from the json
    final organizerProfile = json['organizer_profile'] ?? {};

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
      goals: goals,
      organizerPhone: organizerProfile['phone_number'] ?? '',
      organizerEmail: organizerProfile['email'] ?? '',
      organizerLocation: organizerProfile['location'] ?? '',
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
      'goals': goals.map((goal) => goal.toJson()).toList(),
      'organizer_phone': organizerPhone,
      'organizer_email': organizerEmail,
      'organizer_location': organizerLocation,
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
