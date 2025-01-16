import 'package:flutter/material.dart';

class WorkoutPreferencesCard extends StatelessWidget {
  final List<String> preferences;

  const WorkoutPreferencesCard({
    super.key,
    required this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    if (preferences.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Preferences',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: preferences
                  .map((pref) => Chip(
                        label: Text(pref),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onPrimaryContainer),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
} 