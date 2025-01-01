class Profile {
  final String userId;
  final String name;
  final String bio;
  final String imageUrl;
  final List<String> workoutPreferences;
  final Map<String, String> contactInfo;
  final Map<String, bool> privacySettings;
  final List<Map<String, dynamic>> fitnessHistory;
  final List<Map<String, dynamic>> groupGoals;
  final List<Map<String, dynamic>> groupActivities;
  final String role;

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
    this.role = '',
  });
}
