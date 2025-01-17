import 'package:flutter/material.dart';
import '../../models/group_details.dart';

class GoalsCard extends StatelessWidget {
  final List<Goal> goals;

  const GoalsCard({
    super.key,
    required this.goals,
  });

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const SizedBox.shrink();
    }

    final dailyGoals = goals.where((goal) => goal.type == 'daily').toList();
    final weeklyGoals = goals.where((goal) => goal.type == 'weekly').toList();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Group Goals',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (dailyGoals.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.today,
                      color: Theme.of(context).primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Goals',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...dailyGoals.map((goal) => _buildGoalItem(context, goal)),
              const SizedBox(height: 16),
            ],
            if (weeklyGoals.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      color: Theme.of(context).primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Weekly Goals',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...weeklyGoals.map((goal) => _buildGoalItem(context, goal)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(BuildContext context, Goal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          goal.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: goal.isCompleted ? Colors.green : Colors.grey,
        ),
        title: Text(
          goal.title,
          style: TextStyle(
            decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          goal.description,
          style: TextStyle(
            decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
