import 'package:flutter/material.dart';

class WorkoutBuddyForm extends StatelessWidget {
  final TextEditingController fitnessGoalsController;
  final TextEditingController availabilityController;
  final List<String> workoutPreferences;
  final Function(String, bool) onWorkoutPreferenceChanged;

  final List<String> workoutOptions = [
    'Gym',
    'Yoga',
    'Running',
    'Swimming',
    'Cycling',
    'CrossFit',
    'Boxing',
  ];

  WorkoutBuddyForm({
    super.key,
    required this.fitnessGoalsController,
    required this.availabilityController,
    required this.workoutPreferences,
    required this.onWorkoutPreferenceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: fitnessGoalsController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Fitness Goals',
            hintText: 'Describe your fitness goals',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) =>
              value!.isEmpty ? 'Please describe your fitness goals' : null,
        ),
        const SizedBox(height: 24),
        const Text(
          'Workout Preferences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select the types of workouts you\'re interested in:',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: workoutOptions.map((workout) {
            return FilterChip(
              label: Text(workout),
              selected: workoutPreferences.contains(workout),
              onSelected: (selected) => onWorkoutPreferenceChanged(workout, selected),
            );
          }).toList(),
        ),
        if (workoutPreferences.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one workout preference',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 16),
        TextFormField(
          controller: availabilityController,
          decoration: InputDecoration(
            labelText: 'Availability',
            hintText: 'Enter your workout availability',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) =>
              value!.isEmpty ? 'Please enter your availability' : null,
        ),
      ],
    );
  }
} 