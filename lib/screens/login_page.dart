import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'signup_page.dart';
import 'buddy_finder_dashboard.dart';
import 'group_organizer_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedResponse = prefs.getString('loginResponse');

      if (storedResponse != null && mounted) {
        final loginData = jsonDecode(storedResponse);
        final userType = loginData['user']['userType'];
        _navigateToDashboard(userType);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking login status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToDashboard(String userType) {
    if (userType == 'buddy') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
        (route) => false,
      );
    } else if (userType == 'group') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const GroupOrganizerDashboard()),
        (route) => false,
      );
    }
  }

  void _handleLogin() async {
    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      print('\n=== Login Request ===');
      print('URL: http://192.168.31.36:8000/api/login/');
      print('Headers: {"Content-Type": "application/json"}');
      print('Body: {"username": "$username", "password": "$password"}');

      final response = await http.post(
        Uri.parse('http://192.168.31.36:8000/api/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('\n=== Login Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);
      print('Decoded Response: $jsonResponse');

      if (response.statusCode == 200) {
        print('\n=== Login Successful ===');
        final userType = jsonResponse['user']['userType'];
        print('User Type: $userType');
        print('Token: ${jsonResponse['token']}');

        // Save complete response to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('userType', userType);
        await prefs.setString('token', jsonResponse['token']);
        await prefs.setInt('userId', jsonResponse['user']['id']);
        await prefs.setString('email', jsonResponse['user']['email'] ?? '');
        await prefs.setString('loginResponse',
            jsonEncode(jsonResponse)); // Store complete response

        if (mounted) {
          if (userType == 'buddy') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
              (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Welcome Buddy!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (userType == 'group') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const GroupOrganizerDashboard()),
              (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Welcome Group Organizer!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(jsonResponse['message'] ?? 'Login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error during login: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this helper method to retrieve stored login data
  Future<Map<String, dynamic>?> getStoredLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedResponse = prefs.getString('loginResponse');
    if (storedResponse != null) {
      return jsonDecode(storedResponse);
    }
    return null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _handleLogin,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                    },
                    child: const Text('Forgot Password?'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUpPage()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
