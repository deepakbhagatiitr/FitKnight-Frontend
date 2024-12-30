import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import 'edit_profile_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

      print('\n=== Loading User Profile ===');
      print('User Type: $userType');
      print('User ID: $userId');
      print('Token: $token');

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

      print('\n=== Profile Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Convert API response to Profile model with proper type checking
        final profile = Profile(
          userId: userId.toString(),
          name: jsonData['username'] ?? '',
          bio: jsonData['bio'] ?? '',
          imageUrl: jsonData['profile_image']?.toString() ?? '',
          fitnessGoals: jsonData['fitness_goals'] != null
              ? (jsonData['fitness_goals'] is List
                  ? List<String>.from(jsonData['fitness_goals'])
                  : [jsonData['fitness_goals'].toString()])
              : [],
          contactInfo: {
            'email': jsonData['email'] ?? '',
            'phone': jsonData['phone'] ?? '',
            'location': jsonData['location'] ?? '',
          },
          fitnessHistory: jsonData['fitness_history'] != null &&
                  jsonData['fitness_history'] is List
              ? List<Map<String, dynamic>>.from(jsonData['fitness_history'])
              : [],
          groupGoals:
              jsonData['group_goals'] != null && jsonData['group_goals'] is List
                  ? List<Map<String, dynamic>>.from(jsonData['group_goals'])
                  : [],
          groupActivities: jsonData['group_activities'] != null &&
                  jsonData['group_activities'] is List
              ? List<Map<String, dynamic>>.from(jsonData['group_activities'])
              : [],
        );

        print('\n=== Profile Image URL ===');
        print('Raw URL from API: ${jsonData['profile_image']}');
        print('Processed URL: ${profile.imageUrl}');

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
                          _profile!.bio.isNotEmpty
                              ? _profile!.bio
                              : 'No bio available',
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
                    if (_profile!.contactInfo['email']?.isNotEmpty ?? false)
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(_profile!.contactInfo['email']!),
                      ),
                    if (_profile!.contactInfo['phone']?.isNotEmpty ?? false)
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text('Phone'),
                        subtitle: Text(_profile!.contactInfo['phone']!),
                      ),
                    if (_profile!.contactInfo['location']?.isNotEmpty ?? false)
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: const Text('Location'),
                        subtitle: Text(_profile!.contactInfo['location']!),
                      ),
                  ],
                ),
              ),
            ),

            // Fitness Goals (Show only for workout buddy)
            if (_userType == 'buddy' && _profile!.fitnessGoals.isNotEmpty)
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fitness Goals',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _profile!.fitnessGoals
                            .map((goal) => Chip(label: Text(goal)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

            // Fitness History (Show only for workout buddy)
            if (_userType == 'buddy' && _profile!.fitnessHistory.isNotEmpty)
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
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _profile!.fitnessHistory.length,
                        itemBuilder: (context, index) {
                          final history = _profile!.fitnessHistory[index];
                          return ListTile(
                            title: Text(history['activity'] ?? ''),
                            subtitle: Text(
                              '${history['date']} • ${history['duration']}\n${history['milestone']}',
                            ),
                            isThreeLine: true,
                          );
                        },
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
}
