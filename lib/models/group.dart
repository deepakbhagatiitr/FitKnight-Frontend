class Group {
  final String id;
  final String name;
  final String activity;
  final String activityType;
  final String location;
  final String imageUrl;
  final String schedule;
  final String description;
  final String createdAt;
  final String organizerName;
  final int memberCount;
  final int members;

  Group({
    required this.id,
    required this.name,
    required this.activity,
    required this.activityType,
    required this.location,
    required this.imageUrl,
    required this.schedule,
    required this.description,
    required this.createdAt,
    required this.organizerName,
    required this.memberCount,
    required this.members,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    String imageUrl = json['group_image'] ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = 'http://10.81.1.137:8000$imageUrl';
    }

    final activityType = json['activity_type'] ?? '';

    return Group(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      activity: activityType,
      activityType: activityType,
      location: json['location'] ?? '',
      imageUrl: imageUrl,
      schedule: json['schedule'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
      organizerName: json['organizer_name'] ?? '',
      memberCount: (json['members'] as List?)?.length ?? 0,
      members: (json['members'] as List?)?.length ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'activity_type': activityType,
      'location': location,
      'group_image': imageUrl,
      'schedule': schedule,
      'description': description,
      'created_at': createdAt,
      'organizer_name': organizerName,
      'member_count': memberCount,
    };
  }
}
