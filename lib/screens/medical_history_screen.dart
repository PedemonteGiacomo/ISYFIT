import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class MedicalHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History'),
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Fix for overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
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
                        'Keep track of your clients’ medical history to ensure their safety during training sessions.',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Use this section to review, add, or update important medical information.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Recent Records Section
              _buildSectionTitle('Recent Medical Records'),
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
                        title: 'John Doe - Updated: Dec 29, 2024',
                        icon: Icons.person,
                        onTap: () {
                          Navigator.pushNamed(context, '/client-medical-detail');
                        },
                      ),
                      _buildListTile(
                        title: 'Jane Smith - Updated: Dec 28, 2024',
                        icon: Icons.person,
                        onTap: () {
                          Navigator.pushNamed(context, '/client-medical-detail');
                        },
                      ),
                      _buildListTile(
                        title: 'Tom Brown - Updated: Dec 27, 2024',
                        icon: Icons.person,
                        onTap: () {
                          Navigator.pushNamed(context, '/client-medical-detail');
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
                        label: 'Add New Medical Record',
                        icon: Icons.add_circle_outline,
                        onPressed: () {
                          Navigator.pushNamed(context, '/add-medical-record');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        label: 'Search Medical Records',
                        icon: Icons.search,
                        onPressed: () {
                          Navigator.pushNamed(context, '/search-medical-records');
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
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 32),
      title: Text(title, style: const TextStyle(fontSize: 16)),
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
