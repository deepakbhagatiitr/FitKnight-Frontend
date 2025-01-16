import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_page.dart';
import '../screens/profile_page.dart';
import '../screens/edit_profile_page.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class NavigationService {
  static final _authService = AuthService();

  static Future<void> handleLogout(BuildContext context) async {
    try {
      // Clear all notifications first
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        try {
          await NotificationService.clearAllNotifications(token);
        } catch (e) {
          print('Error clearing notifications: $e');
        }
      }

      // Then proceed with logout
      await _authService.logout();

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to logout')),
      );
    }
  }

  static void navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  static Future<void> navigateToEditProfile(
    BuildContext context,
    Profile profile,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(profile: profile),
      ),
    );
    return result;
  }
}
