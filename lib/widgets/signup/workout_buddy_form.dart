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

  static const List<String> availabilityOptions = [
    'Morning',
    'Afternoon',
    'Evening',
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
              onSelected: (selected) =>
                  onWorkoutPreferenceChanged(workout, selected),
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
        DropdownButtonFormField<String>(
          value: availabilityController.text.isEmpty
              ? null
              : availabilityController.text,
          decoration: InputDecoration(
            labelText: 'Availability',
            hintText: 'Select your availability',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: availabilityOptions.map((String availability) {
            return DropdownMenuItem<String>(
              value: availability,
              child: Text(availability),
            );
          }).toList(),
          validator: (value) => value == null || value.isEmpty
              ? 'Please select your availability'
              : null,
          onChanged: (String? newValue) {
            if (newValue != null) {
              availabilityController.text = newValue;
            }
          },
        ),
      ],
    );
  }
}
