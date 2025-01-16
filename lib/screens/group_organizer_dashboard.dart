import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../services/group_service.dart';
import '../widgets/group/group_card.dart';
import '../widgets/group/member_card.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'create_group_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/common/dashboard_app_bar.dart';

class GroupOrganizerDashboard extends StatefulWidget {
  const GroupOrganizerDashboard({super.key});

  @override
  State<GroupOrganizerDashboard> createState() => _GroupOrganizerDashboardState();
}

class _GroupOrganizerDashboardState extends State<GroupOrganizerDashboard> {
  final _groupService = GroupService();
  final _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Group> _managedGroups = [];
  List<Member> _potentialMembers = [];
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

      final groups = await _groupService.loadManagedGroups();
      final members = await _groupService.loadPotentialMembers();

      setState(() {
        _managedGroups = groups;
        _potentialMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      if (e.toString().contains('401') || e.toString().contains('Not logged in')) {
        await _handleLogout();
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        return token != null;
      },
      child: Scaffold(
        appBar: DashboardAppBar(
          title: 'Group Organizer Dashboard',
          additionalActions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _handleCreateGroup(context),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildDashboardContent(),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_managedGroups.isEmpty)
          const Center(
            child: Text('You haven\'t created any groups yet'),
          )
        else
          ..._managedGroups.map((group) => GroupCard(group: group)),
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
        ..._filterMembers().map((member) => MemberCard(member: member)),
      ],
    );
  }

  List<Member> _filterMembers() {
    final query = _searchQuery.toLowerCase();
    return _potentialMembers.where((member) {
      return member.username.toLowerCase().contains(query) ||
          member.fitnessGoals.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _handleCreateGroup(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupPage(),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
