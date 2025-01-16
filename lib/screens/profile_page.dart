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
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString('userType');

      final profile = await _profileService.loadUserProfile();

      setState(() {
        _userType = userType;
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
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
    if (_isLoading || _profile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_userType == 'group' ? 'Organizer Profile' : 'My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _handleEditProfile(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
    );
  }

  Future<void> _handleEditProfile(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(profile: _profile!),
      ),
    );
    if (result != null) {
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

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal['title'] ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(goal['description'] ?? ''),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal['progress']?.toDouble() ?? 0.0,
            ),
            const SizedBox(height: 8),
            Text(
              '${goal['current']} / ${goal['target']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Deadline: ${goal['deadline']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
