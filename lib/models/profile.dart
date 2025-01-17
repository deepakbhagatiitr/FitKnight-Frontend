import 'dart:convert';

class Profile {
  final String userId;
  final String name;
  final String bio;
  final String imageUrl;
  final List<String> workoutPreferences;
  final Map<String, String> contactInfo;
  final Map<String, bool> privacySettings;
  final List<String> fitnessHistory;
  final List<String> groupGoals;
  final List<String> groupActivities;
  final String role;
  final String groupName;
  final String activityType;
  final String schedule;

  Profile({
    required this.userId,
    required this.name,
    required this.bio,
    required this.imageUrl,
    required this.workoutPreferences,
    required this.contactInfo,
    required this.privacySettings,
    required this.fitnessHistory,
    required this.groupGoals,
    required this.groupActivities,
    required this.role,
    this.groupName = '',
    this.activityType = '',
    this.schedule = '',
  });

  static List<String> _parseWorkoutPreferences(dynamic preferences) {
    if (preferences == null) return [];

    try {
      if (preferences is List) {
        return preferences.map((pref) => pref.toString()).toList();
      }
      if (preferences is String) {
        if (preferences.startsWith('[')) {
          final List<dynamic> parsed = jsonDecode(preferences);
          return parsed.map((p) => p.toString()).toList();
        }
        return [preferences];
      }
    } catch (e) {
      print('Error parsing workout preferences: $e');
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': name,
      'fitness_goals': bio,
      'profile_image': imageUrl,
      'workout_preferences': workoutPreferences,
      'email': contactInfo['email'] ?? '',
      'phone_number': contactInfo['phone'] ?? '',
      'user_location': contactInfo['location'] ?? '',
      'privacy_settings': privacySettings,
      'fitness_history': fitnessHistory,
      'group_goals': groupGoals,
      'group_activities': groupActivities,
      'role': role,
      'group_name': groupName,
      'activity_type': activityType,
      'schedule': schedule,
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id']?.toString() ?? '',
      name: json['username']?.toString() ?? '',
      bio: json['fitness_goals']?.toString() ?? '',
      imageUrl: json['profile_image']?.toString() ?? '',
      workoutPreferences:
          Profile._parseWorkoutPreferences(json['workout_preferences']),
      contactInfo: {
        'email': json['email']?.toString() ?? '',
        'phone': json['phone_number']?.toString() ?? '',
        'location': json['user_location']?.toString() ?? '',
      },
      privacySettings: {
        'showEmail': json['privacy_settings']?['showEmail'] ?? true,
        'showPhone': json['privacy_settings']?['showPhone'] ?? true,
        'showLocation': json['privacy_settings']?['showLocation'] ?? true,
      },
      fitnessHistory: (json['fitness_history'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      groupGoals:
          (json['group_goals'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      groupActivities: (json['group_activities'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      role: json['role']?.toString() ?? '',
      groupName: json['group_name']?.toString() ?? '',
      activityType: json['activity_type']?.toString() ?? '',
      schedule: json['schedule']?.toString() ?? '',
    );
  }
}
