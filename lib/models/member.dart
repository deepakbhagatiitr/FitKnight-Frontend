class Member {
  final String id;
  final String username;
  final String email;
  final String imageUrl;
  final String profileImage;
  final String bio;
  final List<String> fitnessInterests;
  final String fitnessGoals;
  final List<String> workoutPreferences;
  final String availability;
  final String location;

  Member({
    required this.id,
    required this.username,
    required this.email,
    required this.imageUrl,
    required this.profileImage,
    required this.bio,
    required this.fitnessInterests,
    required this.fitnessGoals,
    required this.workoutPreferences,
    required this.availability,
    required this.location,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    String imageUrl = json['profile_image'] ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = 'http://10.81.88.76:8000$imageUrl';
    }

    return Member(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      imageUrl: imageUrl,
      profileImage: imageUrl,
      bio: json['bio'] ?? '',
      fitnessInterests: (json['fitness_interests'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fitnessGoals: json['fitness_goals'] ?? '',
      workoutPreferences: (json['workout_preferences'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      availability: json['availability'] ?? '',
      location: json['user_location'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profile_image': profileImage,
      'bio': bio,
      'fitness_interests': fitnessInterests,
      'fitness_goals': fitnessGoals,
      'workout_preferences': workoutPreferences,
      'availability': availability,
      'user_location': location,
    };
  }
}
