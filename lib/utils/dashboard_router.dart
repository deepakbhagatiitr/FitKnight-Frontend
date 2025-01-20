import 'package:flutter/material.dart';
import '../screens/buddy_finder_dashboard.dart';
import '../screens/group_organizer_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardRouter {
  static Future<Widget> getAppropriateScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('userType');

    if (userType == 'buddy') {
      return const BuddyFinderDashboard();
    } else if (userType == 'group') {
      return const GroupOrganizerDashboard();
    } else {
      return const BuddyFinderDashboard();
    }
  }
} 