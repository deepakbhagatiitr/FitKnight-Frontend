class Profile {
  final String userId;
  String name;
  String bio;
  String imageUrl;
  List<String> fitnessGoals;
  Map<String, bool> privacySettings;
  List<Map<String, dynamic>> fitnessHistory;
  Map<String, String> contactInfo;
  List<Map<String, dynamic>> groupGoals;
  List<Map<String, dynamic>> groupActivities;

  Profile({
    required this.userId,
    required this.name,
    this.bio = '',
    this.imageUrl = '',
    List<String>? fitnessGoals,
    Map<String, bool>? privacySettings,
    List<Map<String, dynamic>>? fitnessHistory,
    Map<String, String>? contactInfo,
    List<Map<String, dynamic>>? groupGoals,
    List<Map<String, dynamic>>? groupActivities,
  })  : fitnessGoals = fitnessGoals ?? [],
        privacySettings = privacySettings ??
            {
              'showEmail': true,
              'showPhone': false,
              'showLocation': true,
              'showFitnessHistory': true,
            },
        fitnessHistory = fitnessHistory ?? [],
        contactInfo = contactInfo ?? {},
        groupGoals = groupGoals ?? [],
        groupActivities = groupActivities ?? [];
}
