class Group {
  final String id;
  final String name;
  final String description;
  final String location;
  final String imageUrl;
  final String organizer;
  final int memberCount;
  final String activity;
  final String schedule;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.organizer,
    required this.memberCount,
    required this.activity,
    required this.schedule,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      imageUrl: json['image_url'] ?? '',
      organizer: json['organizer'] ?? '',
      memberCount: json['member_count'] ?? 0,
      activity: json['activity'] ?? '',
      schedule: json['schedule'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'image_url': imageUrl,
      'organizer': organizer,
      'member_count': memberCount,
      'activity': activity,
      'schedule': schedule,
    };
  }
}
