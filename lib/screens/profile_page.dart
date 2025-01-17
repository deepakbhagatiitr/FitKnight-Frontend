import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/contact_info_card.dart';
import '../widgets/profile/workout_preferences_card.dart';
import '../widgets/profile/profile_milestone_card.dart';
import 'edit_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileService = ProfileService();
  String? _userType;
  Profile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('userType');
      final profile = await _profileService.loadUserProfile();

      if (!mounted) return;

      setState(() {
        _userType = userType;
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  ImageProvider _getProfileImage(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return NetworkImage(imageUrl);
    } else if (imageUrl.isNotEmpty) {
      return NetworkImage('http://10.81.1.137:8000$imageUrl');
    } else {
      return const NetworkImage('https://picsum.photos/200');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userType == 'group' ? 'Organizer Profile' : 'My Profile'),
        actions: [
          if (!_isLoading && _profile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _handleEditProfile(context),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : _profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Could not load profile data',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserInfo,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserInfo,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileHeader(
                          profile: _profile!,
                          getProfileImage: _getProfileImage,
                        ),
                        ContactInfoCard(profile: _profile!),
                        if (_userType == 'buddy')
                          WorkoutPreferencesCard(
                            preferences: _profile!.workoutPreferences,
                          ),
                        if (_userType == 'buddy') _buildFitnessSection(),
                        if (_userType == 'group') _buildGroupSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Future<void> _handleEditProfile(BuildContext context) async {
    if (_profile == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(profile: _profile!),
      ),
    );

    if (result != null && result is Profile) {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
          'showEmail', result.privacySettings['showEmail'] ?? true);
      await prefs.setBool(
          'showPhone', result.privacySettings['showPhone'] ?? true);
      await prefs.setBool(
          'showLocation', result.privacySettings['showLocation'] ?? true);

      setState(() {
        _profile = result;
      });
    }
  }

  Widget _buildFitnessSection() {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitness Milestones',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ProfileMilestoneCard(
                      icon: Icons.emoji_events,
                      title: '10+',
                      subtitle: 'Workouts\nCompleted',
                    ),
                    ProfileMilestoneCard(
                      icon: Icons.access_time,
                      title: '20+',
                      subtitle: 'Hours\nTrained',
                    ),
                    ProfileMilestoneCard(
                      icon: Icons.trending_up,
                      title: '5',
                      subtitle: 'Goals\nAchieved',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupSection() {
    return Column(
      children: [
        if (_profile!.groupGoals.isNotEmpty)
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Group Goals',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _profile!.groupGoals.length,
                    itemBuilder: (context, index) =>
                        _buildGoalCard(_profile!.groupGoals[index]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGoalCard(String goal) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.flag),
        title: Text(goal),
      ),
    );
  }
}
