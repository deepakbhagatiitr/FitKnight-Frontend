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

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
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
      final groups = await _buddyFinderService.loadFitnessGroups();

      setState(() {
        _recommendedBuddies = buddies;
        _fitnessGroups = groups;
        _isLoading = false;
      });
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
    final query = _searchQuery.toLowerCase();
    return _recommendedBuddies.where((buddy) {
      return buddy.name.toLowerCase().contains(query) ||
          buddy.activity.toLowerCase().contains(query);
    }).toList();
  }

  List<Group> get filteredGroups {
    final query = _searchQuery.toLowerCase();
    return _fitnessGroups.where((group) {
      return group.name.toLowerCase().contains(query) ||
          group.activity.toLowerCase().contains(query);
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

  Widget _buildDashboardContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
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
        const SizedBox(height: 24),
        if (filteredBuddies.isNotEmpty) ...[
          Text(
            'Recommended Workout Buddies',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filteredBuddies.length,
              itemBuilder: (context, index) =>
                  BuddyCard(buddy: filteredBuddies[index]),
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (filteredGroups.isNotEmpty) ...[
          Text(
            'Available Fitness Groups',
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
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
