import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class TrainingRecordsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Records'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Section
              _buildSectionTitle('Overview'),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Manage and track your clients’ training progress effectively.',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This section provides insights into training plans, progress updates, and session history.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Recent Training Sessions Section
              _buildSectionTitle('Recent Training Sessions'),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildListTile(
                        title: 'John Doe - Session: Dec 29, 2024',
                        subtitle: 'Focus: Strength Training',
                        icon: Icons.person,
                        onTap: () {
                          Navigator.pushNamed(
                              context, '/client-training-detail');
                        },
                      ),
                      _buildListTile(
                        title: 'Jane Smith - Session: Dec 28, 2024',
                        subtitle: 'Focus: Cardio',
                        icon: Icons.person,
                        onTap: () {
                          Navigator.pushNamed(
                              context, '/client-training-detail');
                        },
                      ),
                      _buildListTile(
                        title: 'Tom Brown - Session: Dec 27, 2024',
                        subtitle: 'Focus: Flexibility',
                        icon: Icons.person,
                        onTap: () {
                          Navigator.pushNamed(
                              context, '/client-training-detail');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Actions Section
              _buildSectionTitle('Actions'),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildActionButton(
                        label: 'Create New Training Plan',
                        icon: Icons.add_circle_outline,
                        onPressed: () {
                          Navigator.pushNamed(context, '/create-training-plan');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        label: 'View All Training Records',
                        icon: Icons.search,
                        onPressed: () {
                          Navigator.pushNamed(context, '/all-training-records');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 32),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onTap,
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
    );
  }
}
