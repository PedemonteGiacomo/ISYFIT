import 'package:flutter/material.dart';
import 'registration_client_screen.dart';
import 'registration_PT_screen.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              const Icon(Icons.arrow_forward_ios, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''), // Removed the text but kept the blue bar
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 8,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 700), // Reduced width
                  child: _buildOptionCard(
                    context: context,
                    icon: Icons.person,
                    title: 'Register as Client',
                    description:
                        'Create an account to be guided by a Personal Trainer or use limited features.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterClientScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 700), //Reduced width
                  child: _buildOptionCard(
                    context: context,
                    icon: Icons.fitness_center,
                    title: 'Register as PT',
                    description:
                        'Sign up as a Personal Trainer to manage your clients and grow your business.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterPTScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
