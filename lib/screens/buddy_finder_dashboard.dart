import 'package:flutter/material.dart';
import 'group_page.dart';
import 'group_details_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _recommendedBuddies = [];
  List<Map<String, dynamic>> _fitnessGroups = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadRecommendedBuddies(),
      _loadFitnessGroups(),
    ]);
  }

  Future<void> _loadRecommendedBuddies() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('\n=== Loading Recommended Buddies ===');
      final response = await http.get(
        Uri.parse(
            'http://192.168.31.36:8000/api/profile/?role=workout_buddy&match_preferences=true'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['results'] ?? [];

        // Map the profiles to buddy format
        _recommendedBuddies = data.map((profile) {
          // Construct full image URL
          String imageUrl = profile['profile_image'] ?? '';
          if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
            imageUrl = 'http://192.168.31.36:8000$imageUrl';
          }

          // Parse fitness goals
          String activity = '';
          try {
            if (profile['fitness_goals'] != null) {
              if (profile['fitness_goals'] is String) {
                final goals = jsonDecode(profile['fitness_goals']);
                activity = goals.isNotEmpty ? goals.first.toString() : '';
              } else if (profile['fitness_goals'] is List) {
                activity = profile['fitness_goals'].isNotEmpty
                    ? profile['fitness_goals'].first.toString()
                    : '';
              }
            }
          } catch (e) {
            print('Error parsing fitness goals: $e');
          }

          return {
            'name': profile['username'] ?? '',
            'activity': activity,
            'availability': profile['availability'] ?? '',
            'image': imageUrl,
            'email': profile['email'] ?? '',
            'location': profile['location'] ?? '',
            'phone': profile['phone_number'] ?? '',
          };
        }).toList();

        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load buddies: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading buddies: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load recommended buddies';
      });
    }
  }

  Future<void> _loadFitnessGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('\n=== Loading Fitness Groups ===');
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
          _fitnessGroups = data.map((group) {
            String imageUrl = group['group_image'] ?? '';
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = 'http://192.168.31.36:8000$imageUrl';
            }

            return {
              'id': group['id']?.toString() ?? '',
              'name': group['name'] ?? group['group_name'] ?? '',
              'activity': group['activity_type'] ?? '',
              'members': group['member_count'] ?? group['members'] ?? 0,
              'location': group['location'] ?? '',
              'image': imageUrl,
              'schedule': group['schedule'] ?? '',
              'organizer': group['organizer'] ?? '',
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to load groups: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading groups: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading groups: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add these to track filter states
  String? _selectedActivity;
  String? _selectedAvailability;

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedActivity,
              decoration: const InputDecoration(labelText: 'Activity'),
              items: ['Yoga', 'CrossFit', 'Weight Training', 'Pilates', 'Gym']
                  .map((activity) => DropdownMenuItem(
                        value: activity,
                        child: Text(activity),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedActivity = value),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAvailability,
              decoration: const InputDecoration(labelText: 'Availability'),
              items: ['Mornings', 'Afternoons', 'Evenings']
                  .map((time) => DropdownMenuItem(
                        value: time,
                        child: Text(time),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedAvailability = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedActivity = null;
                _selectedAvailability = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  // Optional: Add a method to filter the buddies and groups
  List<Map<String, dynamic>> _getFilteredBuddies() {
    if (_searchQuery.isEmpty) return _recommendedBuddies;

    return _recommendedBuddies.where((buddy) {
      final name = buddy['name'].toString().toLowerCase();
      final activity = buddy['activity'].toString().toLowerCase();
      final location = buddy['location'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) ||
          activity.contains(query) ||
          location.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> _getFilteredGroups() {
    if (_searchQuery.isEmpty) return _fitnessGroups;

    return _fitnessGroups.where((group) {
      final name = group['name'].toString().toLowerCase();
      final activity = group['activity'].toString().toLowerCase();
      final location = group['location'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) ||
          activity.contains(query) ||
          location.contains(query);
    }).toList();
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored preferences
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Widget _buildBuddyCard(Map<String, dynamic> buddy) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(buddy['image'] ?? ''),
              onBackgroundImageError: (e, s) {
                print('Error loading buddy image: $e');
              },
            ),
            const SizedBox(height: 8),
            Text(
              buddy['name'] ?? 'No Name',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            // Check if activity exists and is not empty
            if (buddy['activity'] != null &&
                buddy['activity'].toString().isNotEmpty)
              Text(
                buddy['activity'],
                overflow: TextOverflow.ellipsis,
              ),
            // Check if availability exists and is not empty
            if (buddy['availability'] != null &&
                buddy['availability'].toString().isNotEmpty)
              Text(
                buddy['availability'],
                overflow: TextOverflow.ellipsis,
              ),
            // Check if phone exists and is not empty
            if (buddy['phone'] != null && buddy['phone'].toString().isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      buddy['phone'],
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            // Check if location exists and is not empty
            if (buddy['location'] != null &&
                buddy['location'].toString().isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      buddy['location'],
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedBuddies() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            TextButton(
              onPressed: _loadRecommendedBuddies,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_recommendedBuddies.isEmpty) {
      return const Center(
        child: Text('No recommended buddies found'),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recommendedBuddies.length,
        itemBuilder: (context, index) =>
            _buildBuddyCard(_recommendedBuddies[index]),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    // Debug print to see what data we're getting
    print('Building card for group: $group');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: (group['image'] != null && group['image'].isNotEmpty)
              ? NetworkImage(group['image'])
              : null,
          child: (group['image'] == null || group['image'].isEmpty)
              ? const Icon(Icons.group)
              : null,
        ),
        title: Text(group['name'] ?? 'Unnamed Group'), // Add fallback text
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${group['activity'] ?? 'No activity'} • ${group['location'] ?? 'No location'}'),
            if (group['schedule'] != null && group['schedule'].isNotEmpty)
              Text(
                'Schedule: ${group['schedule']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${group['members'] ?? 0}'),
            const Text('members'),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailsPage(
                group: group,
                groupId: group['id']?.toString() ?? '',
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBuddies = _getFilteredBuddies();
    final filteredGroups = _getFilteredGroups();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Your Buddy'),
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
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search buddies or groups',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Recommended Buddies Section
            if (filteredBuddies.isNotEmpty) ...[
              const Text(
                'Recommended Workout Buddies',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredBuddies.length,
                  itemBuilder: (context, index) =>
                      _buildBuddyCard(filteredBuddies[index]),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Available Groups Section
            if (filteredGroups.isNotEmpty) ...[
              const Text(
                'Available Fitness Groups',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredGroups.length,
                itemBuilder: (context, index) =>
                    _buildGroupCard(filteredGroups[index]),
              ),
            ],

            // Show message if no results found
            if (filteredBuddies.isEmpty && filteredGroups.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No buddies or groups found matching your search',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Buddies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Groups',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GroupPage()),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
