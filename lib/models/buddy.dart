import 'dart:convert';
import 'package:flutter/material.dart';

class Buddy {
  final String username;
  final String email;
  final String role;
  final String phoneNumber;
  final String location;
  final String imageUrl;
  final String fitnessGoals;
  final List<String> workoutPreferences;
  final String availability;
  final int matchScore;
  final List<String> matchReasons;

  Buddy({
    required this.username,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.location,
    required this.imageUrl,
    required this.fitnessGoals,
    required this.workoutPreferences,
    required this.availability,
    required this.matchScore,
    required this.matchReasons,
  });

  factory Buddy.fromJson(Map<String, dynamic> json) {
    String imageUrl = json['profile_image'] ?? '';
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = 'http://10.81.93.48:8000$imageUrl';
    }

    List<String> parseWorkoutPreferences(dynamic preferences) {
      if (preferences == null || !(preferences is List)) return [];
      return preferences.map((pref) => pref.toString()).toList();
    }

    int parseMatchScore(dynamic score) {
      if (score == null) return 0;
      if (score is int) return score;
      if (score is String) {
        try {
          return int.parse(score);
        } catch (e) {
          print('Error parsing match_score: $e');
          return 0;
        }
      }
      return 0;
    }

    return Buddy(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      location: json['user_location'] ?? '',
      imageUrl: imageUrl,
      fitnessGoals: json['fitness_goals']?.toString() ?? '',
      workoutPreferences: parseWorkoutPreferences(json['workout_preferences']),
      availability: json['availability'] ?? '',
      matchScore: parseMatchScore(json['match_score']),
      matchReasons:
          (json['match_reasons'] as List?)?.map((e) => e.toString()).toList() ??
              [],
    );
  }
}
