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
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Workout Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: preferences
                  .map((pref) => Chip(
                        avatar:
                            const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          pref,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
