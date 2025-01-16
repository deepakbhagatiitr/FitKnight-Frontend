import '../widgets/notification_badge.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [
          NotificationBadge(),
        ],
      ),
      // ... rest of your dashboard content
    );
  }
} 