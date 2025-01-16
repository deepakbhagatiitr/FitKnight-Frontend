import 'dart:convert';
import 'package:flutter/material.dart';

class Buddy {
  final String name;
  final String activity;
  final String availability;
  final String imageUrl;
  final String email;
  final String location;
  final String phone;

  Buddy({
    required this.name,
    required this.activity,
    required this.availability,
    required this.imageUrl,
    required this.email,
    required this.location,
    required this.phone,
  });

  factory Buddy.fromJson(Map<String, dynamic> json) {
    String imageUrl = json['profile_image'] ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = 'http://10.81.1.137:8000$imageUrl';
    }

    String activity = '';
    try {
      if (json['fitness_goals'] != null) {
        if (json['fitness_goals'] is String) {
          final goals = jsonDecode(json['fitness_goals']);
          activity = goals.isNotEmpty ? goals.first.toString() : '';
        } else if (json['fitness_goals'] is List) {
          activity = json['fitness_goals'].isNotEmpty
              ? json['fitness_goals'].first.toString()
              : '';
        }
      }
    } catch (e) {
      print('Error parsing fitness goals: $e');
    }

    return Buddy(
      name: json['username'] ?? '',
      activity: activity,
      availability: json['availability'] ?? '',
      imageUrl: imageUrl,
      email: json['email'] ?? '',
      location: json['location'] ?? '',
      phone: json['phone_number'] ?? '',
    );
  }
}
