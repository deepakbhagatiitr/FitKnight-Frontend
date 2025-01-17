import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/buddy.dart';
import '../models/group.dart';
import '../services/buddy_finder_service.dart';
import '../widgets/buddy/buddy_card.dart';
import '../widgets/buddy/group_list_item.dart';
import 'group_page.dart';
import 'login_page.dart';
import '../widgets/common/dashboard_app_bar.dart';

class BuddyFinderDashboard extends StatefulWidget {
  const BuddyFinderDashboard({super.key});

  @override
  State<BuddyFinderDashboard> createState() => _BuddyFinderDashboardState();
}

class _BuddyFinderDashboardState extends State<BuddyFinderDashboard> {
  final _buddyFinderService = BuddyFinderService();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<Buddy> _recommendedBuddies = [];
  List<Group> _fitnessGroups = [];
  String _searchQuery = '';
  String _selectedActivity = '';
  String _selectedLocation = '';

  // Lists for filter options
  List<String> _activityTypes = [];
  List<String> _locations = [];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  void _updateFilterOptions() {
    setState(() {
      // Get unique activity types from both buddies and groups
      _activityTypes = {
        ..._recommendedBuddies.expand((b) => b.workoutPreferences),
        ..._fitnessGroups.map((g) => g.activity).where((a) => a.isNotEmpty),
      }.toList();

      // Get unique locations
      _locations = {
        ..._recommendedBuddies.map((b) => b.location),
        ..._fitnessGroups.map((g) => g.location),
      }.where((location) => location.isNotEmpty).toList();
    });
  }

  Future<void> _checkAuthAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final buddies = await _buddyFinderService.loadRecommendedBuddies();
      final groups = await _buddyFinderService.loadMyGroups();

      if (mounted) {
        setState(() {
          _recommendedBuddies = buddies;
          _fitnessGroups = groups;
          _isLoading = false;
        });
      }

      _updateFilterOptions();
    } catch (e) {
      print('Error loading data: $e');
      if (e.toString().contains('401') ||
          e.toString().contains('Not logged in')) {
        _handleLogout();
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  List<Buddy> get filteredBuddies {
    return _recommendedBuddies.where((buddy) {
      final matchesSearch = _searchQuery.isEmpty ||
          buddy.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          buddy.workoutPreferences.any((pref) =>
              pref.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesActivity = _selectedActivity.isEmpty ||
          buddy.workoutPreferences.contains(_selectedActivity);

      final matchesLocation =
          _selectedLocation.isEmpty || buddy.location == _selectedLocation;

      return matchesSearch && matchesActivity && matchesLocation;
    }).toList();
  }

  List<Group> get filteredGroups {
    return _fitnessGroups.where((group) {
      final matchesSearch = _searchQuery.isEmpty ||
          group.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          group.activity.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesActivity =
          _selectedActivity.isEmpty || group.activity == _selectedActivity;

      final matchesLocation =
          _selectedLocation.isEmpty || group.location == _selectedLocation;

      return matchesSearch && matchesActivity && matchesLocation;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DashboardAppBar(title: 'Find Workout Buddies'),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildDashboardContent(),
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

  Widget _buildFilters() {
    return Column(
      children: [
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
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (_activityTypes.isNotEmpty) ...[
                DropdownButton<String>(
                  hint: const Text('Activity Type'),
                  value: _selectedActivity.isEmpty ? null : _selectedActivity,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All Activities'),
                    ),
                    ..._activityTypes.map((activity) => DropdownMenuItem(
                          value: activity,
                          child: Text(activity),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedActivity = value ?? '';
                    });
                  },
                ),
                const SizedBox(width: 16),
              ],
              if (_locations.isNotEmpty) ...[
                DropdownButton<String>(
                  hint: const Text('Location'),
                  value: _selectedLocation.isEmpty ? null : _selectedLocation,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All Locations'),
                    ),
                    ..._locations.map((location) => DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value ?? '';
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFilters(),
        const SizedBox(height: 24),
        if (filteredBuddies.isNotEmpty) ...[
          _buildRecommendedBuddies(),
        ],
        const SizedBox(height: 24),
        if (filteredGroups.isNotEmpty) ...[
          Text(
            'My Groups',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...filteredGroups.map((group) => GroupListItem(group: group)),
        ],
        if (filteredBuddies.isEmpty && filteredGroups.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No buddies or groups found matching your criteria',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendedBuddies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Recommended Workout Buddies',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: filteredBuddies.length,
            itemBuilder: (context, index) {
              final buddy = filteredBuddies[index];
              return BuddyCard(buddy: buddy);
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
