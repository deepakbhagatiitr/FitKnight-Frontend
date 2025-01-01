import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'group_details_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'create_group_page.dart';

class GroupOrganizerDashboard extends StatefulWidget {
  const GroupOrganizerDashboard({super.key});

  @override
  State<GroupOrganizerDashboard> createState() =>
      _GroupOrganizerDashboardState();
}

class _GroupOrganizerDashboardState extends State<GroupOrganizerDashboard> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _managedGroups = [];
  List<Map<String, dynamic>> _potentialMembers = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');

    if (token == null || username == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadManagedGroups(),
      _loadPotentialMembers(),
    ]);
  }

  Future<void> _loadManagedGroups() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final username = prefs.getString('username');

      print('\n=== Loading Managed Groups ===');
      print('Username from prefs: $username');

      if (token == null || username == null) {
        await _handleLogout();
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.31.36:8000/api/groups/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          // Filter groups where user is the organizer by matching username
          _managedGroups = data
              .where((group) => group['organizer_name'] == username)
              .map((group) {
            String imageUrl = group['group_image'] ?? '';
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = 'http://192.168.31.36:8000$imageUrl';
            }

            return {
              'id': group['id'],
              'name': group['name'] ?? '',
              'activity': group['activity_type'] ?? '',
              'members': group['member_count'] ?? 0,
              'location': group['location'] ?? '',
              'image': imageUrl,
              'schedule': group['schedule'] ?? '',
              'description': group['description'] ?? '',
              'created_at': group['created_at'] ?? '',
              'updated_at': group['updated_at'] ?? '',
              'organizer_name': group['organizer_name'] ?? '',
              'is_organizer': true,
            };
          }).toList();
        });
      } else if (response.statusCode == 401) {
        await _handleLogout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load groups: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading groups: $e');
      if (e.toString().contains('401') ||
          e.toString().contains('Not logged in')) {
        await _handleLogout();
        return;
      }
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPotentialMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        await _handleLogout();
        return;
      }

      print('\n=== Loading Potential Members ===');
      final response = await http.get(
        Uri.parse('http://192.168.31.36:8000/api/profile/?role=workout_buddy'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> profiles = data['results'] ?? [];

        setState(() {
          _potentialMembers = profiles.map((profile) {
            String imageUrl = profile['profile_image'] ?? '';
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = 'http://192.168.31.36:8000$imageUrl';
            }

            return {
              'username': profile['username'] ?? '',
              'email': profile['email'] ?? '',
              'image': imageUrl,
              'fitness_goals': profile['fitness_goals'] ?? '',
              'workout_preferences': profile['workout_preferences'] ?? [],
              'availability': profile['availability'] ?? '',
            };
          }).toList();
        });
      } else if (response.statusCode == 401) {
        await _handleLogout();
        throw Exception('Session expired. Please login again.');
      }
    } catch (e) {
      print('Error loading potential members: $e');
      if (e.toString().contains('401')) {
        await _handleLogout();
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        try {
          final response = await http.post(
            Uri.parse('http://192.168.31.36:8000/api/auth/logout/'),
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
          );
          print('Logout response: ${response.statusCode}');
        } catch (e) {
          print('Error calling logout API: $e');
        }
      }

      await prefs.clear();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to logout')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        return token != null;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Group Organizer Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateGroupPage(),
                  ),
                );

                // If group was created successfully, refresh the groups list
                if (result == true) {
                  await _loadManagedGroups();
                }
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Your Groups',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (_managedGroups.isEmpty)
                      const Center(
                        child: Text('You haven\'t created any groups yet'),
                      )
                    else
                      ..._managedGroups.map((group) => Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                        group['image']?.isNotEmpty ?? false
                                            ? NetworkImage(group['image'])
                                            : null,
                                    child: group['image']?.isEmpty ?? true
                                        ? const Icon(Icons.group)
                                        : null,
                                  ),
                                  title: Text(group['name']),
                                  subtitle: Text(
                                      '${group['activity']} • ${group['location']}'),
                                  trailing: Text('${group['members']} members'),
                                ),
                                ButtonBar(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GroupDetailsPage(
                                              group: group,
                                              groupId: group['id'].toString(),
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('View Details'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // TODO: Implement manage members
                                      },
                                      child: const Text('Manage Members'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                    const SizedBox(height: 24),
                    Text(
                      'Potential Members',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search members',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ..._potentialMembers.where((member) {
                      final query = _searchQuery.toLowerCase();
                      return member['username']
                              .toString()
                              .toLowerCase()
                              .contains(query) ||
                          member['fitness_goals']
                              .toString()
                              .toLowerCase()
                              .contains(query);
                    }).map((member) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  member['image']?.isNotEmpty ?? false
                                      ? NetworkImage(member['image'])
                                      : null,
                              child: member['image']?.isEmpty ?? true
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(member['username']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Goals: ${member['fitness_goals']}'),
                                Text('Available: ${member['availability']}'),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        )),
                  ],
                ),
        ),
        floatingActionButton: null,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
