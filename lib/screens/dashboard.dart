// screens/dashboard.dart
import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  final int userId;

  const Dashboard({super.key, required this.userId}); // FIX: added const

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')), // FIX: const Text
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, user $userId'),
            const SizedBox(height: 20), // FIX: const
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId),
                  ),
                );
              },
              child: const Text('Go to Profile'), // FIX: const
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final int userId;

  const ProfilePage(this.userId, {super.key}); // FIX: added const + super.key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')), // FIX: const
      body: Center(
        child: Text('Profile of user $userId'),
      ),
    );
  }
}