import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import 'edit_profile_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/string_extensions.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await http.get(
        Uri.parse('http://192.168.31.36:8000/api/profile/$userId/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('API Response: $userData');

        // Convert contact info values to strings explicitly
        final Map<String, String> contactInfo = {
          'email': (userData['email'] ?? '').toString(),
          'phone': (userData['phone_number'] ?? '').toString(),
          'location': (userData['user_location'] ?? '').toString(),
        };

        // Get privacy settings from SharedPreferences
        final Map<String, bool> privacySettings = {
          'showEmail': prefs.getBool('showEmail') ?? true,
          'showPhone': prefs.getBool('showPhone') ?? true,
          'showLocation': prefs.getBool('showLocation') ?? true,
        };

        print('Contact Info: $contactInfo');
        print('Privacy Settings: $privacySettings');

        final profile = Profile(
          userId: userId.toString(),
          name: userData['username'] ?? '',
          bio: userData['fitness_goals'] ?? '',
          imageUrl: userData['profile_image']?.toString() ?? '',
          workoutPreferences: userData['workout_preferences'] != null
              ? (() {
                  try {
                    if (userData['workout_preferences'] is List) {
                      return List<String>.from(
                          (userData['workout_preferences'] as List)
                              .map((e) => e.toString().capitalize()));
                    }
                  } catch (e) {
                    print('Error parsing workout preferences: $e');
                  }
                  return <String>[];
                })()
              : [],
          contactInfo: contactInfo,
          privacySettings: privacySettings,
          fitnessHistory: [],
          groupGoals: [],
          groupActivities: [],
          role: userData['role'] ?? '',
        );

        setState(() {
          _userType = userType;
          _profile = profile;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
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
      // If the API returns a relative path, construct the full URL
      return NetworkImage('http://192.168.31.36:8000$imageUrl');
    } else {
      // Fallback image
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
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(profile: _profile!),
                ),
              );
              if (result != null) {
                // Update SharedPreferences with new privacy settings
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(
                    'showEmail', result.privacySettings['showEmail'] ?? true);
                await prefs.setBool(
                    'showPhone', result.privacySettings['showPhone'] ?? true);
                await prefs.setBool('showLocation',
                    result.privacySettings['showLocation'] ?? true);

                setState(() {
                  _profile = result;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _getProfileImage(_profile!.imageUrl),
                    onBackgroundImageError: (exception, stackTrace) {
                      print('Error loading profile image: $exception');
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile!.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _profile!.bio.isNotEmpty ? _profile!.bio : '',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contact Information
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (_profile!.contactInfo['email']?.isNotEmpty == true &&
                        _profile!.privacySettings['showEmail'] == true)
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(_profile!.contactInfo['email']!),
                      ),
                    if (_profile!.contactInfo['phone']?.isNotEmpty == true &&
                        _profile!.privacySettings['showPhone'] == true)
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text('Phone'),
                        subtitle: Text(_profile!.contactInfo['phone']!),
                      ),
                    if (_profile!.contactInfo['location']?.isNotEmpty == true &&
                        _profile!.privacySettings['showLocation'] == true)
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: const Text('Location'),
                        subtitle: Text(_profile!.contactInfo['location']!),
                      ),
                    if (!(_profile!.contactInfo['email']?.isNotEmpty == true &&
                            _profile!.privacySettings['showEmail'] == true) &&
                        !(_profile!.contactInfo['phone']?.isNotEmpty == true &&
                            _profile!.privacySettings['showPhone'] == true) &&
                        !(_profile!.contactInfo['location']?.isNotEmpty ==
                                true &&
                            _profile!.privacySettings['showLocation'] == true))
                      const Center(
                        child: Text(
                          'No contact information available',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Workout Preferences (Show only for workout buddy)
            if (_userType == 'buddy' && _profile!.workoutPreferences.isNotEmpty)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workout Preferences',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _profile!.workoutPreferences
                            .map((pref) => Chip(
                                  label: Text(pref),
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  labelStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

            // Fitness History
            if (_userType == 'buddy')
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fitness History',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: const Text('Weight Training Started'),
                            subtitle: const Text(
                                'Started with basic strength training'),
                            trailing: const Text('Jan 2023'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.directions_run),
                            title: const Text('Running Milestone'),
                            subtitle: const Text('Completed first 5K run'),
                            trailing: const Text('Mar 2023'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.sports_gymnastics),
                            title: const Text('Flexibility Achievement'),
                            subtitle: const Text('Mastered basic yoga poses'),
                            trailing: const Text('Jun 2023'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Fitness Milestones
            if (_userType == 'buddy')
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
                          _buildMilestoneCard(
                            context,
                            icon: Icons.emoji_events,
                            title: '10+',
                            subtitle: 'Workouts\nCompleted',
                          ),
                          _buildMilestoneCard(
                            context,
                            icon: Icons.access_time,
                            title: '20+',
                            subtitle: 'Hours\nTrained',
                          ),
                          _buildMilestoneCard(
                            context,
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

            // Group Goals (Show only for group organizer)
            if (_userType == 'group' && _profile!.groupGoals.isNotEmpty)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Group Goals',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _profile!.groupGoals.length,
                        itemBuilder: (context, index) {
                          final goal = _profile!.groupGoals[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal['title'] ?? '',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
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
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Deadline: ${goal['deadline']}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // Group Activities (Show only for group organizer)
            if (_userType == 'group' && _profile!.groupActivities.isNotEmpty)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Group Activities',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _profile!.groupActivities.length,
                        itemBuilder: (context, index) {
                          final activity = _profile!.groupActivities[index];
                          return ListTile(
                            title: Text(activity['name'] ?? ''),
                            subtitle: Text(
                              '${activity['schedule']} at ${activity['time']}\n${activity['location']} • ${activity['participants']} participants',
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
