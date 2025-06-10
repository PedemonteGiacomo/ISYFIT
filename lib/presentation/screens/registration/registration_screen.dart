import 'package:flutter/material.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
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
    final theme = Theme.of(context);
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
              // Icon Section
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.primaryColor.withOpacity(
                    0.1), // or theme.colorScheme.primary.withOpacity(0.1)
                child: Icon(
                  icon,
                  color: theme.primaryColor, // or theme.colorScheme.primary
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Title & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.arrow_forward_ios,
                  size: 20, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Registration',
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPortrait =
                MediaQuery.of(context).orientation == Orientation.portrait;
            final widthFactor = isPortrait ? 0.9 : 0.6;
            final cardWidth =
                (constraints.maxWidth * widthFactor).clamp(320.0, 700.0);

            return Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardWidth),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildOptionCard(
                          context: context,
                          icon: Icons.person,
                          title: 'Register as Client',
                          description:
                              'Create an account to be guided by a Personal Trainer or use limited features.',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RegisterClientScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildOptionCard(
                          context: context,
                          icon: Icons.fitness_center,
                          title: 'Register as PT',
                          description:
                              'Sign up as a Personal Trainer to manage your clients and grow your business.',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPTScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
